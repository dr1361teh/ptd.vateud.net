class Examination < ActiveRecord::Base
  attr_accessible :date, :departure_airport, :destination_airport, :examiner_id, :rating_id

  # has_many :pilots, :inverse_of => :examination
  has_and_belongs_to_many :pilots
  belongs_to :examiner
  belongs_to :rating

  attr_accessible :pilot_ids

  validates :date, :departure_airport, :destination_airport, :examiner_id, :rating, :presence => true

  scope :upcoming, lambda {
    where("date > ?", Time.now)
  }


  # after_create :send_initial_mail
  after_save :send_mail

  # def send_initial_mail
  #   PtdMailer.examination_mail_pilots(self).deliver
  #   PtdMailer.examination_mail_instructors(self).deliver
  #   PtdMailer.examination_mail_examiner(self).deliver
  # end

  def list_pilot_names
    pilot_names = []
    self.pilots.each {|pilot| pilot_names << pilot.name }
    pilot_names.join(", ")
  end

  def self.records_by_day(start)
    records = unscoped.where(created_at: start.beginning_of_day..Time.zone.now)    
    records = records.group('date(created_at)')
    records = records.order('date(created_at)')
    records = records.select('date(created_at) as created_at, count(*) as count')
    records.each_with_object({}) do |record, counts|
      counts[record.created_at.to_date] = record.count
    end
  end

  def self.records_by_month(start)
    records = unscoped.where(created_at: start.beginning_of_month..Time.zone.now)    
    records = records.group('date(created_at)')
    records = records.order('date(created_at)')
    records = records.select('date(created_at) as created_at, count(*) as count')
    records.each_with_object({}) do |record, counts|
      counts[record.created_at.to_date] = record.count
    end
  end

  def send_mail
    if self.date_changed?
      PtdMailer.delay.examination_mail_pilots(self) if self.pilots.count > 0
      PtdMailer.delay.examination_mail_instructors(self) if self.pilots.count > 0
      PtdMailer.delay.examination_mail_examiner(self)
      PtdMailer.delay.examination_mail_admins(self)
    end
  end
  
  rails_admin do 
    navigation_label 'Operations records' 

    show do
      field :date
      field :rating
      field :examiner
      field :departure_airport
      field :destination_airport
      field :pilots
      # field :pilots do
      #   pretty_value do          
      #     pilots = bindings[:object].pilots if bindings[:object].pilots
      #     for pilot in pilots
      #       bindings[:view].link_to "#{pilot.name}", bindings[:view].rails_admin.edit_path('pilot', pilot.id)
      #     end
      #   end
      # end
    end

    edit do
      field :date
      field :rating
      field :examiner
      field :departure_airport
      field :destination_airport
      # field :pilots
      field :pilots do
        associated_collection_cache_all false  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          examination = bindings[:object]
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            scope = scope.unscoped.where(upgraded: false, theory_passed: true, ready_for_practical: true).reorder('name ASC')
            # scope = scope.limit(30)
          }
        end
      end      
    end

    list do
      field :id
      field :date do
        column_width 220
        pretty_value do          
          id = bindings[:object].id
          date = bindings[:object].date
          bindings[:view].link_to "#{date}", bindings[:view].rails_admin.show_path('examination', id)
        end
      end

      field :rating do
        column_width 60        
        label "Rating" 
      end
      field :examiner
      field :departure_airport do
        column_width 60        
        label "Departure" 
      end
      field :destination_airport  do
        column_width 60        
        label "Destination" 
      end
    end  
       
  end
end
