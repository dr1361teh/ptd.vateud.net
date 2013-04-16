class AtcRating < ActiveRecord::Base
  attr_accessible :name, :priority

  has_many :pilots

  validates :name, :presence => true

  default_scope order('priority ASC')

  rails_admin do 
    navigation_label 'Administrative records'   
    label "ATC rating" 
    label_plural "ATC ratings"
    list do
      include_fields :name, :priority
    end    

    edit do
      exclude_fields :pilots
    end
  end
end
