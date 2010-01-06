# my wall discussion posts
class Me::PublicMessagesController < Me::BaseController
  permissions 'public_messages'

  helper 'wall_posts'
  stylesheet 'messages'

  #
  # display a list of recent message activity
  #
  def index
    @posts = current_user.wall_discussion.posts.paginate(:order => 'created_at DESC', :page => params[:page])
  end

  def show
    @post = current_user.wall_discussion.posts.find_by_id(params[:id])
    return render_not_found unless @post
  end

  def destroy
    post = Post.find params[:id]
    if post.discussion == current_user.wall_discussion
      post.destroy
      redirect_to my_public_messages_url
    else
      render_permission_denied
    end
  end

  def create
    @post = StatusPost.create do |post|
      post.body = params[:post][:body]
      post.body = post.body[0..140] if post.body
      post.discussion = current_user.wall_discussion
      post.user = current_user
      post.recipient = current_user
      post.body_html = post.lite_html
    end
  rescue ActiveRecord::RecordInvalid => exc
    flash_message :exception => exc
  ensure
    redirect_to referer
  end

  protected

  def context
    super
    if action?(:show)
      add_context(I18n.t(:messages), my_messages_url)
      add_context(I18n.t(:public), my_public_messages_url)
      add_context(h(@post.body[0..48]), my_public_message_path(@post))
    end
  end

end
