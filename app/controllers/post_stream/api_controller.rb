

class PostStream::ApiController < ApplicationController


skip_before_filter :verify_authenticity_token

 before_filter :api_request

 protected

 def api_request
   if params[:apikey]
     user = EndUser.find_by_api_token(params[:apikey])
     process_login user
   end
   true
 end



 public

 def create

   if myself.has_role?('post_stream_manage')

     args = params.slice(:target_type,:target_id,:subject,:message)
     target = PostStreamTarget.find_by_target_type_and_target_id(args[:target_type],args[:target_id])

     if target 
       @post = PostStreamPost.new :body => args[:message], :title => args[:subject], :end_user_id => myself.id, :posted_by => target.target

       if @post.save
         PostStreamPostTarget.link_post_to_target(@post,target)

         return render :status=> 200, :json => { :status => 'posted', :id => @post.id }
       else
         return render :status=> 422, :json => { :status => 'invalid', :errors => @post.errors.full_messages }
       end
     end

     return render :status => 404, :json => { :status => 'target_not_found' }
   end

   return render :status => 403, :json => { :status => 'not_authorized' }
 end

end
