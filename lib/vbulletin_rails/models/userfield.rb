module VBulletinRails
  class Userfield < ActiveRecord::Base #:nodoc:
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    if Rails.version >= '3.2'
      self.primary_key = :userid
      self.table_name = PREFIX + 'userfield'
    else
      set_primary_key(:userid)
      set_table_name(PREFIX + 'userfield')
    end

    attr_accessible :field2, :field7, :field32, :field5, :field19, :field23, :field2

    
    # For human# Aliases
    #alias :location :field2
    #alias :first_name :field7
    #alias :last_name :field32
    #alias :country, :field19
    #alias :state, :field23
    #alias :localization, :field2

    belongs_to :user, :foreign_key => :userid

    #
    # Instance Methods
    #

    def full_name
      "#{self.field7} #{self.field32}"
    end

    def cellphone
      self.field5
    end
  end
end
