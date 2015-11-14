class Course::Assessment::Answer < ActiveRecord::Base
  include Workflow
  actable

  workflow do
    state :attempting do
      event :finalise, transitions_to: :submitted
    end
    state :submitted do
      event :unsubmit, transitions_to: :attempting
      event :publish, transitions_to: :graded
    end
    state :graded
  end

  validate :validate_consistent_assessment
  validate :validate_assessment_state, if: :attempting?
  validates :submitted_at, :grade, presence: true, unless: :attempting?
  validates :submitted_at, :grade, :grader, :graded_at, absence: true, if: :attempting?
  validates :grader, :graded_at, presence: true, if: :graded?
  validate :validate_consistent_grade, unless: :attempting?

  belongs_to :submission, inverse_of: :answers
  belongs_to :question, class_name: Course::Assessment::Question.name, inverse_of: nil
  belongs_to :grader, class_name: User.name, inverse_of: nil
  has_one :auto_grading, class_name: Course::Assessment::Answer::AutoGrading.name,
                         inverse_of: :answer

  accepts_nested_attributes_for :actable

  # Creates an Auto Grading job for this answer. This saves the answer if there are pending changes.
  #
  # @return [Course::Assessment::Answer::AutoGradingJob] The job instance.
  # @raise [ArgumentError] When the question cannot be auto graded.
  def auto_grade!
    fail ArgumentError unless question.auto_gradable?

    save!
    create_auto_grading!
    Course::Assessment::Answer::AutoGradingJob.new(auto_grading)
  end

  protected

  def finalise
    self.grade = 0
    self.submitted_at = Time.zone.now
  end

  def publish
    self.grader = User.stamper
    self.graded_at = Time.zone.now
  end

  private

  def validate_consistent_assessment
    errors.add(:question, :consistent_assessment) if question.assessment != submission.assessment
  end

  def validate_assessment_state
    errors.add(:submission, :attemptable_state) unless submission.attempting?
  end

  def validate_consistent_grade
    errors.add(:grade, :consistent_grade) if grade.present? && grade > question.maximum_grade
  end
end
