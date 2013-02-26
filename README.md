# TheComments 0.5.0

TheComments - comments tree for your web project.

![TheComments](https://raw.github.com/open-cook/the_comments/master/the_comments.jpg)

### Main features

* **Comments tree** (via [TheSortableTree](https://github.com/the-teacher/the_sortable_tree) custom helper)
* **No captcha!** Tricks and traps for SpamBots instead Captcha
* **IP** and **User Agent** black lists
* Useful **Cache counters** for Users and Commentable objects
* Designed for external content filters ( **sanitize**, **RedCloth**, **Markdown**)
* **Open comments** with moderation
* Creator of comments can see his comments via **view_token** ( _view token_ stored with cookies)
* Denormalization of commentable objects. We store **commentable_title** and **commentable_url** in each comment, for fast access to commentable object
* Highlighting of selected comment onLoad and onHahChange (via comment anchor)

### Requires

```ruby
gem 'awesome_nested_set'
gem 'the_sortable_tree'
gem 'state_machine'
```

### Anti Spam system

User agent must have:

* Cookies support
* JavaScript and Ajax support

_Usually spambot not support Cookies and JavaScript_

Comment form has:

* fake (hidden) fields

_Usually spam bot puts data in fake inputs_

Trap via time:

* User should be few seconds on page, before comment sending (by default 5 sec)

_Usually spam bots works faster, than human. We can try to use this feature of behavior_

## Installation

```ruby
gem 'the_comments'
```

**bundle**

```ruby
bundle exec rails g model comment               --migration=false
bundle exec rails g model ip_black_list         --migration=false
bundle exec rails g model user_agent_black_list --migration=false

bundle exec rake the_comments_engine:install:migrations
```

**bundle exec rake db:migrate**

### Assets

**app/assets/javascripts/application.js**

```js
//= require the_comments
```

**app/assets/stylesheets/application.css**

```css
/*
 *= require the_comments
*/
```

### User Model

```ruby
class User < ActiveRecord::Base
  # Your implementation of role policy
  def admin?
    self == User.first
  end

  # include TheComments methods
  include TheCommentsUser
  
  # denormalization for commentable objects
  def commentable_title
    login
  end

  def commentable_url
    [class.to_s.tableize, login].join('/')
  end

  # Comments moderator checking (simple example)
  # Usually comment's holder should be moderator
  def comment_moderator? comment
    admin? || id == comment.holder_id
  end

end
```

**User#coments** - comments. Set of all created comments

```ruby
User.first.comments
# => Array of comments, where User is creator (owner)
```

**User#comcoms** - commentable comments. Set of all comments of all owned commentable objects of this user.

```ruby
User.first.comcoms
# => Array of all comments of all owned commentable objects, where User is holder
# Usually comment's holder should be moderator of this comments
# because this user should maintain cleaness of his commentable objects
```

**Attention!** You should be sure that you understand who is owner, and who is holder of comments!

### Commentable Model (Page, Blog, Article, User ...)

**Attention!** User model can be commentable object also.

```ruby
class Blog < ActiveRecord::Base
  # include TheComments methods
  include TheCommentsCommentable

  # (!) Every commentable Model must have next 2 methods
  # denormalization for commentable objects
  def commentable_title
    title
  end

  def commentable_url
    [self.class.to_s.tableize, slug_id].join('/')
  end
end
```

### Comment Model

```ruby
class Comment < ActiveRecord::Base
  # include TheComments methods
  include TheCommentsBase

  # Define comment's avatar url
  # Usually we use Comment#user (owner of comment) to define avatar
  # @blog.comments.includes(:user) <= use includes(:user) to decrease queries count
  # comment#user.avatar_url

  # Simple way to define avatar url
  def avatar_url
    hash = Digest::MD5.hexdigest self.id.to_s
    "http://www.gravatar.com/avatar/#{hash}?s=30&d=identicon"
  end

  # Define your filters for content
  # Expample for: gem 'RedCloth', gem 'sanitize'
  # your personal SmilesProcessor
  def prepare_content
    text = self.raw_content
    text = RedCloth.new(text).to_html
    text = SmilesProcessor.new(text)
    text = Sanitize.clean(text, Sanitize::Config::RELAXED)
    self.content = text
  end
end
```

### IP, User Agent black lists

Models must looks like this:

```ruby
class IpBlackList < ActiveRecord::Base
  include TheCommentsBlackUserAgent
end

class UserAgentBlackList < ActiveRecord::Base
  include TheCommentsBlackIp
end
```

### Commentable controller

```ruby
class BlogsController < ApplicationController
  include TheCommentsController::Cookies
  include TheCommentsController::ViewToken

  def show
    @blog     = Blog.where(id: params[:id]).with_states(:published).first
    @comments = @blog.comments.with_state([:draft, :published]).nested_set
  end
end
```

### View

```ruby
%h1= @blog.title
%p=  @blog.content

= render partial: 'comments/tree', locals: { comments_tree: @comments, commentable: @blog }
```

## Configuration

**config/initializers/the_comments.rb**

```ruby
TheComments.configure do |config|
  config.max_reply_depth = 3                                # 3 by default
  config.tolerance_time  = 15                               # 5 (sec) by default
  config.empty_inputs    = [:email, :message, :commentBody] # [:message] by default
end
```

* **max_reply_depth** - comments tree nesting by default
* **tolerance_time** - how many seconds user should spend on page, before comment send
* **empty_inputs** - names of hidden (via css) fields for spam detecting

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request