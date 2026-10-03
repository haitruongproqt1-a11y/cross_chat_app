import React, { useState } from 'react';
import { 
  Camera, Edit3, MoreHorizontal, Heart, MessageCircle, Share2, 
  Send, Image as ImageIcon, Smile, MapPin, Key, Shield, CheckCheck, Check
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { CURRENT_USER } from '../data/mockData';

export const DiaryScreen: React.FC = () => {
  const { posts, likePost, addComment, createPost, language, showToast } = useApp();
  const [newPostText, setNewPostText] = useState('');
  const [commentInputs, setCommentInputs] = useState<Record<string, string>>({});

  const handlePostSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPostText.trim()) return;
    createPost(newPostText);
    setNewPostText('');
  };

  const handleCommentSubmit = (postId: string) => {
    const text = commentInputs[postId];
    if (!text || !text.trim()) return;
    addComment(postId, text);
    setCommentInputs(prev => ({ ...prev, [postId]: '' }));
  };

  return (
    <div className="pb-24 max-w-md mx-auto min-h-screen bg-[#F8FAFC]">
      {/* Profile Cover Banner */}
      <div className="relative h-44 bg-gradient-to-r from-amber-500/80 via-sky-600 to-indigo-600 overflow-hidden">
        <img
          src="https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80"
          alt="West Lake Sunset Hanoi"
          className="w-full h-full object-cover"
          referrerPolicy="no-referrer"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent" />

        <button 
          onClick={() => showToast('Cập nhật ảnh bìa mới')}
          className="absolute top-3 right-3 w-8 h-8 rounded-full bg-black/40 backdrop-blur-md text-white flex items-center justify-center hover:bg-black/60 transition-colors"
          title="Đổi ảnh bìa"
        >
          <Camera className="w-4 h-4" />
        </button>
      </div>

      {/* Profile Info Header Card */}
      <div className="px-4 -mt-12 relative z-10 space-y-3">
        <div className="flex items-end justify-between">
          {/* Avatar with online status */}
          <div className="relative">
            <div className="w-22 h-22 rounded-full p-1 bg-white shadow-md">
              <img
                src={CURRENT_USER.avatar}
                alt={CURRENT_USER.name}
                className="w-full h-full rounded-full object-cover"
                referrerPolicy="no-referrer"
              />
            </div>
            <span className="absolute bottom-1 right-1 w-4 h-4 bg-emerald-500 border-2 border-white rounded-full"></span>
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-2 pb-1">
            <button 
              onClick={() => showToast('Chỉnh sửa thông tin hồ sơ')}
              className="px-3.5 py-1.5 bg-sky-700 hover:bg-sky-800 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-xs transition-colors"
            >
              <Edit3 className="w-3.5 h-3.5" />
              <span>{language === 'vi' ? 'Chỉnh sửa' : 'Edit profile'}</span>
            </button>

            <button 
              onClick={() => showToast('Tùy chọn trang cá nhân')}
              className="p-1.5 bg-white border border-slate-200 text-slate-600 hover:text-slate-900 rounded-xl transition-colors"
            >
              <MoreHorizontal className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Name and Key Badge */}
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-lg font-black text-slate-900">
              {CURRENT_USER.name}
            </h2>

            <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-50 text-amber-800 text-[11px] font-bold rounded-full border border-amber-300">
              <Key className="w-3 h-3 text-amber-600" />
              <span>Key chính</span>
            </span>
          </div>

          <p className="text-xs text-slate-600 leading-relaxed mt-1">
            {CURRENT_USER.bio}
          </p>

          {/* Meta Info Badges */}
          <div className="flex flex-wrap items-center gap-2 mt-2.5 text-[11px] text-slate-700">
            <span className="px-2.5 py-1 bg-white border border-slate-200 rounded-lg font-medium flex items-center gap-1">
              🎂 1998
            </span>
            <span className="px-2.5 py-1 bg-white border border-slate-200 rounded-lg font-medium flex items-center gap-1">
              📍 Hà Nội
            </span>
            <span className="px-2.5 py-1 bg-white border border-slate-200 rounded-lg font-medium flex items-center gap-1">
              💼 Kỹ sư phần mềm
            </span>
          </div>
        </div>

        {/* Feed Post Composer */}
        <div className="bg-white rounded-2xl p-3 border border-slate-200 shadow-xs space-y-2.5 mt-3">
          <div className="flex items-center gap-2.5">
            <img
              src={CURRENT_USER.avatar}
              alt="Avatar"
              className="w-9 h-9 rounded-full object-cover shrink-0"
              referrerPolicy="no-referrer"
            />
            <input
              type="text"
              value={newPostText}
              onChange={(e) => setNewPostText(e.target.value)}
              placeholder={language === 'vi' ? 'Bạn đang nghĩ gì hôm nay, Nam?' : "What's on your mind, Nam?"}
              className="flex-1 text-xs py-2 px-3 bg-slate-100/80 rounded-xl outline-hidden focus:bg-slate-100"
            />
            {newPostText.trim() && (
              <button
                onClick={handlePostSubmit}
                className="p-2 bg-sky-700 text-white rounded-xl hover:bg-sky-800 transition-colors"
              >
                <Send className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          <div className="flex items-center justify-around pt-2 border-t border-slate-100 text-[11px] font-medium text-slate-600">
            <button 
              onClick={() => showToast('Chọn hình ảnh tải lên')}
              className="flex items-center gap-1.5 hover:text-sky-600"
            >
              <ImageIcon className="w-4 h-4 text-emerald-600" />
              <span>{language === 'vi' ? 'Ảnh/Video' : 'Photo/Video'}</span>
            </button>
            <button 
              onClick={() => showToast('Chọn cảm xúc bài viết')}
              className="flex items-center gap-1.5 hover:text-sky-600"
            >
              <Smile className="w-4 h-4 text-amber-500" />
              <span>{language === 'vi' ? 'Cảm xúc' : 'Feelings'}</span>
            </button>
            <button 
              onClick={() => showToast('Thêm vị trí check-in')}
              className="flex items-center gap-1.5 hover:text-sky-600"
            >
              <MapPin className="w-4 h-4 text-rose-500" />
              <span>{language === 'vi' ? 'Vị trí' : 'Location'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Feed Posts List */}
      <div className="p-4 space-y-4">
        {posts.map((post) => (
          <div
            key={post.id}
            className="bg-white rounded-3xl p-4 border border-slate-200/80 shadow-xs space-y-3"
          >
            {/* Post Author Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="relative">
                  <img
                    src={post.avatar}
                    alt={post.author}
                    className="w-10 h-10 rounded-full object-cover border border-slate-200"
                    referrerPolicy="no-referrer"
                  />
                  <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border border-white rounded-full"></span>
                </div>

                <div>
                  <div className="flex items-center gap-1.5">
                    <h3 className="text-xs font-bold text-slate-900">
                      {post.author}
                    </h3>
                    {post.roleTag && (
                      <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 bg-blue-50 text-blue-700 text-[10px] font-semibold rounded-full border border-blue-200">
                        <Shield className="w-2.5 h-2.5" />
                        <span>{post.roleTag}</span>
                      </span>
                    )}
                  </div>
                  <p className="text-[10px] text-slate-400">
                    {post.timeAgo} • {post.privacy === 'friends' ? (language === 'vi' ? 'Bạn bè' : 'Friends') : (language === 'vi' ? 'Công khai' : 'Public')}
                  </p>
                </div>
              </div>

              <button className="text-slate-400 hover:text-slate-700 p-1">
                <MoreHorizontal className="w-4 h-4" />
              </button>
            </div>

            {/* Post Content */}
            <p className="text-xs text-slate-800 leading-relaxed">
              {post.content}
            </p>

            {/* Post Images Showcase */}
            {post.images && post.images.length > 0 && (
              <div className="rounded-2xl overflow-hidden border border-slate-100 relative">
                {post.images.length === 1 ? (
                  <div className="relative">
                    <img
                      src={post.images[0]}
                      alt="Post visual"
                      className="w-full h-56 object-cover"
                      referrerPolicy="no-referrer"
                    />
                    {post.locationTag && (
                      <div className="absolute bottom-2.5 left-2.5 bg-black/60 backdrop-blur-md text-white text-[10px] font-medium px-2 py-1 rounded-lg flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-rose-400" />
                        <span>{post.locationTag}</span>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="grid grid-cols-2 gap-1.5">
                    <div className="aspect-square bg-slate-100 overflow-hidden">
                      <img
                        src={post.images[0]}
                        alt="Mobile preview"
                        className="w-full h-full object-cover"
                        referrerPolicy="no-referrer"
                      />
                    </div>
                    <div className="grid grid-rows-2 gap-1.5">
                      <div className="bg-slate-100 overflow-hidden">
                        <img
                          src={post.images[1]}
                          alt="Laptop build"
                          className="w-full h-full object-cover"
                          referrerPolicy="no-referrer"
                        />
                      </div>
                      <div className="bg-slate-100 overflow-hidden">
                        <img
                          src={post.images[2]}
                          alt="Team release celebration"
                          className="w-full h-full object-cover"
                          referrerPolicy="no-referrer"
                        />
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Likes and stats summary */}
            <div className="flex items-center justify-between text-[11px] text-slate-500 pt-1 border-t border-slate-100">
              <div className="flex items-center gap-1.5">
                <span className="flex -space-x-1">
                  <span className="w-4 h-4 rounded-full bg-rose-500 text-white flex items-center justify-center text-[9px]">❤️</span>
                  <span className="w-4 h-4 rounded-full bg-sky-500 text-white flex items-center justify-center text-[9px]">👍</span>
                </span>
                <span>{post.likedByText || `${post.likesCount} ${language === 'vi' ? 'lượt thích' : 'likes'}`}</span>
              </div>

              <div className="flex items-center gap-2">
                <span>{post.commentsCount} {language === 'vi' ? 'bình luận' : 'comments'}</span>
                <span>•</span>
                <span>{post.sharesCount} {language === 'vi' ? 'chia sẻ' : 'shares'}</span>
              </div>
            </div>

            {/* Action buttons: Like, Comment, Share */}
            <div className="flex items-center justify-around py-1 border-t border-b border-slate-100 text-xs font-semibold">
              <button
                onClick={() => likePost(post.id)}
                className={`flex items-center gap-1.5 py-1 px-3 rounded-lg transition-colors ${
                  post.isLiked ? 'text-rose-600' : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <Heart className={`w-4 h-4 ${post.isLiked ? 'fill-rose-600' : ''}`} />
                <span>{post.isLiked ? (language === 'vi' ? 'Đã thích' : 'Liked') : (language === 'vi' ? 'Thích' : 'Like')}</span>
              </button>

              <button className="flex items-center gap-1.5 py-1 px-3 text-slate-600 hover:text-slate-900 rounded-lg transition-colors">
                <MessageCircle className="w-4 h-4" />
                <span>{language === 'vi' ? 'Bình luận' : 'Comment'}</span>
              </button>

              <button 
                onClick={() => showToast('Đã sao chép liên kết bài viết')}
                className="flex items-center gap-1.5 py-1 px-3 text-slate-600 hover:text-slate-900 rounded-lg transition-colors"
              >
                <Share2 className="w-4 h-4" />
                <span>{language === 'vi' ? 'Chia sẻ' : 'Share'}</span>
              </button>
            </div>

            {/* Comments List */}
            {post.comments && post.comments.length > 0 && (
              <div className="space-y-2 pt-1">
                {post.comments.map((comment) => (
                  <div key={comment.id} className="flex items-start gap-2 bg-slate-50 p-2.5 rounded-2xl">
                    <img
                      src={comment.avatar}
                      alt={comment.author}
                      className="w-7 h-7 rounded-full object-cover shrink-0 mt-0.5"
                      referrerPolicy="no-referrer"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="text-[11px] font-bold text-slate-800">
                          {comment.author}
                        </span>
                        <span className="text-[9px] text-slate-400 font-mono">
                          {comment.timeAgo}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-600 leading-snug mt-0.5">
                        {comment.content}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Comment Input Box */}
            <div className="flex items-center gap-2 pt-1">
              <img
                src={CURRENT_USER.avatar}
                alt="Me"
                className="w-7 h-7 rounded-full object-cover shrink-0"
                referrerPolicy="no-referrer"
              />
              <div className="flex-1 relative flex items-center">
                <input
                  type="text"
                  value={commentInputs[post.id] || ''}
                  onChange={(e) => setCommentInputs(prev => ({ ...prev, [post.id]: e.target.value }))}
                  onKeyDown={(e) => e.key === 'Enter' && handleCommentSubmit(post.id)}
                  placeholder={language === 'vi' ? 'Viết câu trả lời...' : 'Write a reply...'}
                  className="w-full pl-3 pr-8 py-1.5 bg-slate-100 text-xs rounded-xl outline-hidden focus:bg-white focus:ring-1 focus:ring-sky-500"
                />
                <button
                  type="button"
                  onClick={() => handleCommentSubmit(post.id)}
                  className="absolute right-2 text-sky-600 hover:text-sky-800"
                >
                  <Send className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        ))}

        {/* End of Feed Indicator */}
        <div className="text-center py-6 space-y-1">
          <div className="w-8 h-8 rounded-full bg-slate-200/80 text-slate-500 flex items-center justify-center mx-auto">
            <CheckCheck className="w-4 h-4 text-emerald-600" />
          </div>
          <p className="text-xs text-slate-400 font-medium">
            {language === 'vi' ? 'Bạn đã xem hết tin mới trên tường nhà hôm nay' : 'You have viewed all updates for today'}
          </p>
        </div>
      </div>
    </div>
  );
};
