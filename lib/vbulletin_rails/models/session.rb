require 'date'
module VBulletinRails

  # Automatic class for handling VBulletin users sessions.
  class Session < ActiveRecord::Base

    attr_accessible :password, :lastactivity, :lastvisit

    # VBulletin tables prefix in database. It must set same as <tt>$config['Database']['tableprefix']</tt> in your VBulletin forum
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    # Timeout used to set <tt>last_visit</tt> in database. Taken from VBulletin. Do not touch.
    VB_SESSION_TIMEOUT = 900

    if Rails.version >= '3.2'
      self.primary_key = :sessionhash
      self.table_name = PREFIX + 'session'
    else
      set_primary_key(:sessionhash)
      set_table_name(PREFIX + 'session')
    end

    belongs_to :user, :foreign_key => :userid

    # Scopes
    scope :registered_user, where("userid <> ? and loggedin = ?", 0, 2)
    scope :online,  where("(userid <> ? and loggedin = ?) or (userid= ? and loggedin = ?) and lastactivity > ?", 0, 2, 0, 0, (DateTime.now - 15.minutes).to_i)
    scope :by_ids, lambda {|user_ids| user_ids.present?? where("userid in (?)", user_ids) : where("1 = 0")}
    scope :except_ids, lambda {|user_ids| where("userid NOT in (?)", user_ids) unless user_ids.blank?}

    # Updates VBulletin session timestamp on the application side, to make them consistent with VBulletin on the forum side.
    def update_timestamps
      unless user.blank?
        last_activity = user.lastactivity
        nowstamp = Time.now.to_i
        last_visit = (((nowstamp - last_activity) > VB_SESSION_TIMEOUT) ? last_activity : user.lastvisit)
        update_attributes(:lastactivity => nowstamp)
	user.lastactivity = nowstamp
	user.lastvisit = last_visit
	user.save
        return [nowstamp, last_visit]
      end
      return [0, 0]
    end

    # Sets user session for VBulletin. Needs VBulletinRails::User object, or email or username.
    # Controller <tt>request</tt> is mandatory!
    #
    #   VBulletinRails::Session.set :request => request, :user => vb_user
    #   VBulletinRails::Session.set :request => request, :email => 'user@example.com'
    #   VBulletinRails::Session.set :request => request, :username => 'username'
    def self.set options = {}
      options = options.symbolize_keys
      request = check_request options

      user = nil
      user = options[:user]
      user = User.find_by_email(options[:email]) if options[:email] and user.blank?
      user = User.find_by_username(options[:username]) if options[:username] and user.blank?
      raise VBulletinRailsException, 'User not found' unless user.is_a?(User)

      nowstamp = Time.now.to_i
      alt_ip = VBulletinRails::fetch_alt_ip(request.headers)
      sessionhash = Digest::MD5.hexdigest((rand * Time.now.to_i * Time.now.usec).to_s)

      connection.execute("INSERT INTO `#{table_name}`
                          (`sessionhash`, `userid`, `host`, `idhash`, `lastactivity`, `location`, `useragent`)
                          VALUES
                          ('#{sessionhash}', '#{user.userid}', '#{alt_ip}', '#{VBulletinRails::idhash(alt_ip, request.user_agent)}',
                          '#{nowstamp}', 'application', '#{request.user_agent}')")

      return find_by_sessionhash(sessionhash)
    end

    # Returns VBulletinRails::Session object, needs session hash and request
    #
    #   VBulletinRails::Session.get :request => request, :sessionhash => 'f588c74c9d6e1c7ad05abf6bcae2186f'
    def self.get options = {}
      options = options.symbolize_keys
      request = check_request options
      idhash = VBulletinRails::idhash(VBulletinRails::fetch_alt_ip(request.headers), request.user_agent)
      session = find_by_sessionhash(options[:sessionhash].to_s)

      if session
        return (session.idhash == idhash && (Time.now.to_i - session.lastactivity) < VB_SESSION_TIMEOUT) ? session : false;
      end
      return false
    end

    # Destroys session with given session hash.
    def self.destroy sessionhash
      session = find_by_sessionhash(sessionhash)
      session.destroy if session
    end

    private
    #:nodoc:
    def self.check_request options = {}
      request = options[:request]
      raise VBulletinRailsException, 'Request is mandatory' unless request
      return request
    end

  end
end
