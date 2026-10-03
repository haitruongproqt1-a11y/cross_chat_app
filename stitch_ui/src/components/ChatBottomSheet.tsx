import React from 'react';
import { Eye, Pin, BellOff, Settings, Trash2, ChevronRight } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const ChatBottomSheet: React.FC = () => {
  const { 
    activeSheetContact, 
    setActiveSheetContact, 
    pinChat, 
    deleteChat, 
    markAsRead, 
    language,
    setCurrentScreen,
    setActiveChatId
  } = useApp();

  if (!activeSheetContact) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 backdrop-blur-xs transition-opacity animate-in fade-in duration-200">
      {/* Backdrop click to dismiss */}
      <div 
        className="absolute inset-0" 
        onClick={() => setActiveSheetContact(null)} 
      />

      <div className="relative w-full max-w-md bg-white rounded-t-3xl p-5 shadow-2xl z-10 space-y-4 pb-8 border-t border-slate-100 animate-in slide-in-from-bottom duration-300">
        {/* Drag handle */}
        <div className="w-12 h-1.5 bg-slate-300 rounded-full mx-auto mb-2" />

        {/* Profile Card Header */}
        <div className="flex items-center gap-3.5 p-3.5 bg-sky-50/70 rounded-2xl border border-sky-100/80">
          <div className="relative">
            <img 
              src={activeSheetContact.avatar} 
              alt={activeSheetContact.name} 
              className="w-12 h-12 rounded-full object-cover ring-2 ring-white shadow-xs"
              referrerPolicy="no-referrer"
            />
            {activeSheetContact.isOnline && (
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-base font-bold text-slate-900 truncate">
              {activeSheetContact.name}
            </h3>
            <p className="text-xs text-emerald-600 font-medium flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block"></span>
              {language === 'vi' ? 'Đang hoạt động' : 'Active now'}
            </p>
          </div>
        </div>

        {/* Actions list */}
        <div className="bg-slate-50/90 rounded-2xl border border-slate-100 divide-y divide-slate-100 overflow-hidden">
          {/* Mark as read */}
          <button
            onClick={() => markAsRead(activeSheetContact.id)}
            className="w-full flex items-center justify-between p-3.5 text-left hover:bg-slate-100/80 transition-colors group"
          >
            <div className="flex items-center gap-3 text-slate-800 font-medium text-sm">
              <Eye className="w-4 h-4 text-sky-600 group-hover:scale-110 transition-transform" />
              <span>{language === 'vi' ? 'Đánh dấu đã đọc' : 'Mark as read'}</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </button>

          {/* Pin chat */}
          <button
            onClick={() => {
              pinChat(activeSheetContact.id);
              setActiveSheetContact(null);
            }}
            className="w-full flex items-center justify-between p-3.5 text-left hover:bg-slate-100/80 transition-colors group"
          >
            <div className="flex items-center gap-3 text-slate-800 font-medium text-sm">
              <Pin className={`w-4 h-4 ${activeSheetContact.isPinned ? 'text-amber-500 rotate-45' : 'text-amber-600'} group-hover:scale-110 transition-transform`} />
              <span>
                {language === 'vi'
                  ? activeSheetContact.isPinned ? 'Bỏ ghim cuộc trò chuyện' : 'Ghim cuộc trò chuyện lên đầu'
                  : activeSheetContact.isPinned ? 'Unpin chat' : 'Pin chat to top'}
              </span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </button>

          {/* Mute */}
          <button
            onClick={() => {
              setActiveSheetContact(null);
            }}
            className="w-full flex items-center justify-between p-3.5 text-left hover:bg-slate-100/80 transition-colors group"
          >
            <div className="flex items-center gap-3 text-slate-800 font-medium text-sm">
              <BellOff className="w-4 h-4 text-slate-600 group-hover:scale-110 transition-transform" />
              <span>{language === 'vi' ? 'Tắt thông báo (Bật im lặng)' : 'Mute notifications'}</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </button>

          {/* Group Settings / customize */}
          <button
            onClick={() => {
              setActiveChatId(activeSheetContact.id);
              setActiveSheetContact(null);
              setCurrentScreen('chat_detail');
            }}
            className="w-full flex items-center justify-between p-3.5 text-left hover:bg-slate-100/80 transition-colors group"
          >
            <div className="flex items-center gap-3 text-slate-800 font-medium text-sm">
              <Settings className="w-4 h-4 text-slate-700 group-hover:rotate-45 transition-transform" />
              <span>{language === 'vi' ? 'Cài đặt & Tùy chỉnh nhóm' : 'Chat & Group Settings'}</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </button>
        </div>

        {/* Delete conversation */}
        <button
          onClick={() => deleteChat(activeSheetContact.id)}
          className="w-full flex items-center justify-center gap-2 p-3.5 bg-rose-50 hover:bg-rose-100 text-rose-600 font-semibold text-sm rounded-2xl border border-rose-100 transition-colors"
        >
          <Trash2 className="w-4 h-4 text-rose-600" />
          <span>{language === 'vi' ? 'Xóa cuộc trò chuyện (Không thể khôi phục)' : 'Delete conversation (Permanent)'}</span>
        </button>
      </div>
    </div>
  );
};
