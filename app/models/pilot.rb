class Pilot < ActiveRecord::Base
  attr_accessible :atc_rating_id, :division_id, :email, :examination_id, :instructor_id, :name,
                  :practical_passed, :rating_id, :theory_passed, :upgraded, :vacc, :vatsimid,
                  :token_issued, :theory_score, :practical_score, :notes, :token_issued_date,
                  :theory_passed_date, :practical_passed_date, :upgraded_date, :instructor_assigned_date,
                  :slug, :examination_feedback, :token_reissued, :token_reissued_date, :ready_for_practical,
                  :theory_failed, :theory_failed_date, :practical_failed, :practical_failed_date
  
  extend FriendlyId
  friendly_id :url, use: :slugged

  # default_scope order('id DESC')
  default_scope order('pilots.id ASC')

  scope :theoretical, where(:theory_passed => true)
  scope :practical, where(:practical_passed => true)
  scope :graduated, where(:upgraded => true)
  scope :active, where(:upgraded => false)
  scope :unexamined, where(:examination_id => nil)

  belongs_to :atc_rating
  belongs_to :division
  belongs_to :examination, :inverse_of => :pilots
  has_and_belongs_to_many :trainings
  belongs_to :instructor
  belongs_to :rating
  has_many :pilot_files, :inverse_of => :pilot

  accepts_nested_attributes_for :pilot_files, :allow_destroy => true
  attr_accessible :pilot_files_attributes, :allow_destroy => true

  validates :name, :email, :atc_rating_id, :division_id, :rating_id, :vatsimid, :presence => true
  validates :name, :length => { :minimum => 4 }
  validates :vatsimid, :length => { :minimum => 6 }
  validates :vatsimid, :numericality => true
  validate :rating_requirements, :on => :create
  validate :one_rating_per_pilot, :on => :create

  after_create :send_welcome_mail
  after_save :saving_callbacks
  before_save :before_saving_callbacks

  def one_rating_per_pilot
    if Pilot.active.where(:vatsimid => self.vatsimid).count > 0
      errors.add(:vatsimid, 'Cannot enroll for more than one rating at a time!')
    end
  end

  def rating_requirements
    if member = Member.find_by_cid(self.vatsimid)
      ratings = member.humanized_pilot_rating.split(",").each {|r| r.strip!}
      errors.add(:rating_id, 'You already have at least P1 rating, no need to enroll for Newbie training!') if self.rating_id == 3 && ratings.include?("P1")
      errors.add(:rating_id, 'You already have this rating, no need to enroll again!') if ratings.include?(self.rating.name)
      if self.rating.name == "P2" && !ratings.include?("P1")
        errors.add(:rating_id, 'You are not eligible for this rating yet. Get the pre-requisite ratings first!')
      end
    end
  end

  def self.chart_data(start = 1.year.ago)
    pilots = pilots_by_day(start)
    examinations = Examination.records_by_day(start)
    trainings = Training.records_by_day(start)
    (start.to_date..Date.today).map do |date|
      {
        created_at: date,
        pilots: pilots[date].to_i || 0,
        examinations: examinations[date].to_i || 0,
        trainings: trainings[date].to_i || 0
      }
    end
  end

  def self.pilots_by_day(start)
    pilots = unscoped.where(created_at: start.beginning_of_day..Time.zone.now)    
    pilots = pilots.group('date(created_at)')
    pilots = pilots.order('date(created_at)')
    pilots = pilots.select('date(created_at) as created_at, count(*) as count')
    pilots.each_with_object({}) do |pilot, counts|
      counts[pilot.created_at.to_date] = pilot.count
    end
  end

  def self.yearly_chart_data(start = 1.year.ago)
    pilots = pilots_by_month(start)
    examinations = Examination.records_by_month(start)
    trainings = Training.records_by_month(start)
    (start.to_date..Date.today).map do |date|
      {
        created_at: date,
        pilots: pilots[date].to_i || 0,
        examinations: examinations[date].to_i || 0,
        trainings: trainings[date].to_i || 0
      }
    end
  end

  def self.pilots_by_month(start)
    pilots = unscoped.where(created_at: start.beginning_of_month..Time.zone.now)    
    pilots = pilots.group('date(created_at)')
    pilots = pilots.order('date(created_at)')
    pilots = pilots.select('date(created_at) as created_at, count(*) as count')
    pilots.each_with_object({}) do |pilot, counts|
      counts[pilot.created_at.to_date] = pilot.count
    end
  end

  def url
    Digest::SHA1.hexdigest self.name+self.created_at.to_s+self.vatsimid.to_s+"rgy345sjk"
  end

  def send_welcome_mail
    PtdMailer.welcome_mail_pilot(self).deliver
    PtdMailer.welcome_mail_users(self).deliver
  end

  def saving_callbacks
    send_instructor_emails 
    send_token_emails
    send_theory_emails
    send_practical_emails
    send_upgraded_emails
    send_examination_feedback
    send_ready_for_practical_emails  
    send_failure_emails  
  end

  def before_saving_callbacks
    save_chronography
  end

  def send_instructor_emails
    if self.instructor_id_changed? && self.instructor
      PtdMailer.instructor_mail_pilot(self).deliver
      PtdMailer.instructor_mail_instructor(self).deliver
    end    
  end

  def send_token_emails
    if self.token_issued_changed? && self.token_issued?
      PtdMailer.token_mail_pilot(self).deliver
    end  
    if self.token_reissued_changed? && self.token_reissued?
      PtdMailer.token_mail_pilot(self).deliver
    end   
  end

  def send_theory_emails
    if self.theory_passed_changed? && self.theory_passed?
      PtdMailer.theory_mail_pilot(self).deliver
      PtdMailer.theory_mail_instructor(self).deliver
    end
  end

  def send_practical_emails
    if self.practical_passed_changed? && self.practical_passed?
      PtdMailer.practical_mail_pilot(self).deliver
      PtdMailer.practical_mail_instructor(self).deliver
      PtdMailer.practical_mail_admin(self).deliver
    end
  end

  def send_failure_emails
    if self.theory_failed_changed? && self.theory_failed?      
      PtdMailer.theory_fail_mail_instructors(self).deliver
      PtdMailer.theory_fail_mail_pilot(self).deliver
    end
    if self.practical_failed_changed? && self.practical_failed?      
      PtdMailer.practical_fail_mail_instructors(self).deliver
      PtdMailer.practical_fail_mail_pilot(self).deliver
    end
  end

  def send_upgraded_emails
    if self.upgraded_changed? && self.upgraded?
      PtdMailer.upgraded_mail_pilot(self).deliver
    end 
  end

  def send_ready_for_practical_emails
    if self.ready_for_practical_changed? && self.ready_for_practical?
      PtdMailer.ready_for_practical_mail_examiners(self).deliver
      PtdMailer.ready_for_practical_mail_pilot(self).deliver
    end 
  end

  def send_examination_feedback
    if self.examination_feedback_changed?
      unless self.examination_feedback.blank?
        PtdMailer.feedback_mail_pilot(self).deliver
        PtdMailer.feedback_mail_instructor(self).deliver
      end
    end
  end

  def save_chronography
    if self.token_issued_changed? && self.token_issued?
      self.token_issued_date = Time.now
    elsif self.token_issued_changed?
      self.token_issued_date = nil
    end  
    if self.token_reissued_changed? && self.token_reissued?
      self.token_reissued_date = Time.now
    elsif self.token_reissued_changed?
      self.token_reissued_date = nil
    end 
    if self.theory_passed_changed? && self.theory_passed?
      self.theory_passed_date = Time.now
    elsif self.theory_passed_changed?
      self.theory_passed_date = nil
    end  
    if self.practical_passed_changed? && self.practical_passed?
      self.practical_passed_date = Time.now
    elsif self.practical_passed_changed?
      self.practical_passed_date = nil
    end  
    if self.theory_failed_changed? && self.theory_failed?
      self.theory_failed_date = Time.now
    elsif self.theory_failed_changed?
      self.theory_failed_date = nil
    end 
    if self.practical_failed_changed? && self.practical_failed?
      self.practical_failed_date = Time.now
    elsif self.practical_failed_changed?
      self.practical_failed_date = nil
    end
    if self.upgraded_changed? && self.upgraded?
      self.upgraded_date = Time.now
    elsif self.upgraded_changed?
      self.upgraded_date = nil
    end 
    if self.instructor_id_changed? && self.instructor
      self.instructor_assigned_date = Time.now
    end 
  end

  rails_admin do 
    navigation_label 'Operations records'   

    list do
      field :id do
        column_width 40
      end
      field :name do
        column_width 170
        pretty_value do          
          id = bindings[:object].id
          name = bindings[:object].name
          bindings[:view].link_to "#{name}", bindings[:view].rails_admin.show_path('pilot', id)
        end
      end
      field :email do
        column_width 190
      end
      field :rating do
        column_width 60        
        label "Desired Rating" 
      end
      field :vatsimid do
        label "Vatsim ID"
        column_width 80
      end
      field :division do
        column_width 80
      end
      field :vacc do
        column_width 100
      end
      field :atc_rating
      field :trainings
      field :token_issued
      field :token_issued_date
      field :token_reissued
      field :theory_passed
      field :theory_passed_date
      field :theory_score
      field :ready_for_practical
      field :examination
      field :practical_passed
      field :practical_passed_date
      field :practical_score
      field :upgraded
      field :upgraded_date      
    end

    edit do      
      field :name 
      field :email
      field :rating do
        label "Desired Rating"       
      end
      field :vatsimid do
        label "Vatsim ID"       
      end
      field :division
      field :vacc
      field :atc_rating
      field :instructor      
      field :trainings
      field :token_issued     
      field :theory_failed
      field :token_reissued      
      field :theory_passed      
      field :theory_score
      field :ready_for_practical
      field :examination do
        # associated_collection_cache_all false  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          pilot = bindings[:object]
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            if pilot.examination_id.nil?
              scope = scope.where("date > ?", Time.now)
              scope = scope.limit(30)
            else
              scope = scope.where("date > ? OR id = ?", Time.now, pilot.examination_id)
              scope = scope.limit(30)
            end
          }
        end
      end   
      field :practical_failed 
      field :practical_passed      
      field :practical_score
      field :examination_feedback
      field :upgraded      
      field :pilot_files
      field :notes
    end

    show do      
      field :name 
      field :email
      field :rating do
        label "Desired Rating"       
      end
      field :vatsimid do
        label "Vatsim ID"       
      end
      field :division
      field :vacc
      field :atc_rating
      field :instructor
      field :instructor_assigned_date
      field :token_issued
      field :token_issued_date
      field :theory_failed
      field :theory_failed_date
      field :token_reissued
      field :token_reissued_date
      field :theory_passed
      field :theory_passed_date
      field :theory_score
      field :ready_for_practical
      field :examination
      field :practical_failed
      field :practical_failed_date
      field :practical_passed
      field :practical_passed_date
      field :practical_score
      field :examination_feedback
      field :upgraded
      field :upgraded_date
      field :pilot_files
      field :notes
    end
       
  end
end
