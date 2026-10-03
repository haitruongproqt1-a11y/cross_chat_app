import React, { useState } from 'react';
import { Search, SlidersHorizontal, Plus, Pin, Trash2, MoreVertical, CheckCheck } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { STORIES_DATA } from '../data/mockData';
import { ChatItem } from '../types';

export const ChatListScreen: React.FC = () => {
  const { 
    chats, 
    setCurrentScreen, 
    setActiveChatId, 
    setActiveSheetContact,
    pinChat,
    deleteChat,
    language 
  } = useApp();

  const [activeCategory, setActiveCategory] = useState<'all' | 'unread' | 'work_school'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [swipedChatId, setSwipedChatId] = useState<string | null>('kini_dev_team'); // Default swipe preview as in screenshot

  const filteredChats = chats.filter(chat => {
    const matchesSearch = chat.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          chat.lastMessage.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;
    if (activeCategory === 'unread') return (chat.unreadCount || 0) > 0;
    if (activeCategory === 'work_school') return chat.category === 'work_school';
    return true;
  });

  const unreadCount = chats.filter(c => (c.unreadCount || 0) > 0).length;
  const workCount = chats.filter(c => c.category === 'work_school').length;

  return (
    <div className="pb-24 max-w-md mx-auto min-h-screen bg-[#F8FAFC]">
      {/* Search Header */}
      <div className="p-4 pb-2">
        <div className="relative flex items-center">
          <Search className="absolute left-3.5 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={language === 'vi' ? 'Tìm kiếm cuộc trò chuyện, tin nhắn...' : 'Search conversations, messages...'}
            className="w-full pl-9 pr-10 py-2 text-xs bg-slate-100/90 hover:bg-slate-100 focus:bg-white rounded-xl border border-slate-200/60 focus:border-sky-500 focus:ring-2 focus:ring-sky-500/15 outline-hidden transition-all placeholder:text-slate-400"
          />
          <button 
            className="absolute right-3 text-slate-400 hover:text-slate-600"
            title="Bộ lọc nâng cao"
          >
            <SlidersHorizontal className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Filter Categories Chips */}
      <div className="flex items-center gap-2 px-4 py-1.5 overflow-x-auto no-scrollbar">
        <button
          onClick={() => setActiveCategory('all')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap transition-all ${
            activeCategory === 'all'
              ? 'bg-sky-600 text-white font-medium shadow-xs shadow-sky-600/30'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          {language === 'vi' ? 'Tất cả' : 'All'}
        </button>

        <button
          onClick={() => setActiveCategory('unread')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap flex items-center gap-1.5 transition-all ${
            activeCategory === 'unread'
              ? 'bg-sky-600 text-white font-medium shadow-xs shadow-sky-600/30'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <span>{language === 'vi' ? 'Chưa đọc' : 'Unread'}</span>
          <span className={`text-[10px] px-1 rounded-full font-bold ${
            activeCategory === 'unread' ? 'bg-sky-700 text-white' : 'bg-sky-100 text-sky-700'
          }`}>
            {unreadCount}
          </span>
        </button>

        <button
          onClick={() => setActiveCategory('work_school')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap flex items-center gap-1.5 transition-all ${
            activeCategory === 'work_school'
              ? 'bg-sky-600 text-white font-medium shadow-xs shadow-sky-600/30'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <span>In Motion / Trường học</span>
          <span className={`text-[10px] px-1 rounded-full font-bold ${
            activeCategory === 'work_school' ? 'bg-sky-700 text-white' : 'bg-slate-100 text-slate-600'
          }`}>
            {workCount}
          </span>
        </button>
      </div>

      {/* Stories Carousel */}
      <div className="px-4 py-3 border-b border-slate-100/80">
        <div className="flex items-center gap-3.5 overflow-x-auto no-scrollbar py-1">
          {STORIES_DATA.map((story) => (
            <div 
              key={story.id} 
              className="flex flex-col items-center gap-1 shrink-0 cursor-pointer group"
              onClick={() => {
                const target = chats.find(c => c.name.toLowerCase().includes(story.name.toLowerCase()));
                if (target) {
                  setActiveChatId(target.id);
                  setCurrentScreen('chat_detail');
                }
              }}
            >
              <div className="relative">
                <div className={`w-13 h-13 rounded-full p-[2px] transition-transform group-hover:scale-105 ${
                  story.unread ? 'bg-gradient-to-tr from-sky-500 via-sky-400 to-indigo-500' : 'bg-slate-200'
                }`}>
                  <img
                    src={story.avatar}
                    alt={story.name}
                    className="w-full h-full rounded-full object-cover border-2 border-white"
                    referrerPolicy="no-referrer"
                  />
                </div>
                {story.isLive && (
                  <span className="absolute -bottom-0.5 left-1/2 -translate-x-1/2 bg-emerald-500 text-white text-[9px] font-bold px-1 rounded-full border border-white">
                    LIVE
                  </span>
                )}
              </div>
              <span className="text-[11px] text-slate-700 font-medium truncate max-w-[60px] text-center">
                {story.name}
              </span>
            </div>
          ))}

          {/* Add story button */}
          <div 
            onClick={() => setCurrentScreen('diary')}
            className="flex flex-col items-center gap-1 shrink-0 cursor-pointer group"
          >
            <div className="w-13 h-13 rounded-full bg-slate-100 border-2 border-dashed border-slate-300 flex items-center justify-center text-slate-500 group-hover:border-sky-500 group-hover:text-sky-600 transition-colors">
              <Plus className="w-5 h-5" />
            </div>
            <span className="text-[11px] text-slate-600 font-medium">
              {language === 'vi' ? 'Tạo tin' : 'Add story'}
            </span>
          </div>
        </div>
      </div>

      {/* Chat Items List */}
      <div className="divide-y divide-slate-100">
        {filteredChats.map((chat) => {
          const isSwiped = swipedChatId === chat.id;

          return (
            <div key={chat.id} className="relative overflow-hidden group bg-white">
              {/* Swipe Action Buttons Revealed */}
              <div className="absolute inset-y-0 right-0 flex items-stretch">
                <button
                  onClick={() => pinChat(chat.id)}
                  className="w-16 bg-amber-500 hover:bg-amber-600 text-white flex flex-col items-center justify-center gap-1 transition-colors"
                >
                  <Pin className="w-4 h-4" />
                  <span className="text-[10px] font-bold">
                    {chat.isPinned ? 'Bỏ Ghim' : 'Ghim'}
                  </span>
                </button>
                <button
                  onClick={() => deleteChat(chat.id)}
                  className="w-16 bg-rose-600 hover:bg-rose-700 text-white flex flex-col items-center justify-center gap-1 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                  <span className="text-[10px] font-bold">Xóa</span>
                </button>
              </div>

              {/* Main Chat Item Row */}
              <div
                onClick={() => {
                  setActiveChatId(chat.id);
                  setCurrentScreen('chat_detail');
                }}
                className={`relative flex items-center gap-3 p-3.5 bg-white transition-transform duration-300 cursor-pointer hover:bg-slate-50/80 ${
                  isSwiped ? '-translate-x-32' : 'translate-x-0'
                }`}
              >
                {/* Avatar with status indicator */}
                <div className="relative shrink-0">
                  <img
                    src={chat.avatar}
                    alt={chat.name}
                    className="w-12 h-12 rounded-full object-cover border border-slate-200"
                    referrerPolicy="no-referrer"
                  />
                  {chat.isOnline && (
                    <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
                  )}
                </div>

                {/* Name, Message and Badges */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-0.5">
                    <div className="flex items-center gap-1.5 truncate pr-2">
                      <h3 className="text-sm font-bold text-slate-900 truncate">
                        {chat.name}
                      </h3>

                      {chat.roleBadge && (
                        <span
                          className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium shrink-0 flex items-center gap-0.5 border ${
                            chat.roleBadge.type === 'owner'
                              ? 'bg-amber-50 text-amber-700 border-amber-300'
                              : 'bg-blue-50 text-blue-700 border-blue-200'
                          }`}
                        >
                          {chat.roleBadge.text}
                        </span>
                      )}
                    </div>

                    <div className="flex items-center gap-1 shrink-0">
                      {chat.isPinned && (
                        <Pin className="w-3 h-3 text-amber-500 fill-amber-500 rotate-45" />
                      )}
                      <span className="text-[11px] text-slate-400 font-mono">
                        {chat.timestamp}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between">
                    <p className="text-xs text-slate-500 truncate pr-2">
                      {chat.lastMessage}
                    </p>

                    <div className="flex items-center gap-1 shrink-0">
                      {chat.unreadCount && chat.unreadCount > 0 ? (
                        <span className="min-w-[18px] h-[18px] px-1 bg-sky-600 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                          {chat.unreadCount}
                        </span>
                      ) : (
                        <CheckCheck className="w-3.5 h-3.5 text-sky-500" />
                      )}

                      {/* Three dot trigger for action sheet */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setActiveSheetContact(chat);
                        }}
                        className="p-1 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-full transition-colors ml-1"
                      >
                        <MoreVertical className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* Swipe trigger toggle helper button */}
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setSwipedChatId(isSwiped ? null : chat.id);
                }}
                title={isSwiped ? 'Đóng vuốt' : 'Xem thao tác vuốt (Ghim / Xóa)'}
                className="absolute right-1 top-1.5 opacity-0 group-hover:opacity-100 text-[10px] text-slate-400 hover:text-sky-600 z-10 px-1 py-0.5 bg-white/80 rounded"
              >
                {isSwiped ? '◀' : 'Swipe ▶'}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};
