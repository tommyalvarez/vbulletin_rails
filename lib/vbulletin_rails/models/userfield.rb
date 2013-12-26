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

    attr_accessible :field2, :field7, :field32

    
    # For human# Aliases
    #alias :location :field2
    #alias :first_name :field7
    #alias :last_name :field32

    belongs_to :user, :foreign_key => :userid
  end
end
