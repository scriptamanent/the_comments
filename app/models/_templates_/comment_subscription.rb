class CommentSubscription < ActiveRecord::Base
  include ::TheComments::CommentSubscription::User
end
