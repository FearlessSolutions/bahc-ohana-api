class Admin < ApplicationRecord
  # Devise already checks for presence of email and password.
  validates :name, presence: true
  validates :email, email: true, uniqueness: { case_sensitive: false }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable

  def locations
    Location.where("'#{email}' = ANY (admin_emails)")
  end

  def domain
    /.*@(.*)/.match(email)[1]
  end
end
