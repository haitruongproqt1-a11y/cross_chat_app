import React, { useState } from 'react';
import { 
  ChevronLeft, Phone, Video, MoreVertical, Pin, X, Play, Pause, 
  MapPin, Send, Lock, Smile, Paperclip, Mic, Shield, Key, ChevronRight
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const GroupChatScreen: React.FC = () => {
  const { 
    setCurrentScreen, 
    startCall, 
    setShowTransferKeyModal, 
    userRole, 
    groupSettings, 
    messages, 
    addMessage,
    language,
    showToast 
  } = useApp();

  const [inputVal, setInputVal] = useState('');
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const [showPinned, setShowPinned] = useState(true);

  const canSendMessage = !groupSettings.onlyAdminChat || userRole === 'owner' || userRole === 'deputy';

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputVal.trim()) return;
    if (!canSendMessage) {
      showToast(language === 'vi' ? 'Bạn không có quyền gửi tin trong nhóm này' : 'You do not have permission to send messages');
      return;
    }
    addMessage(inputVal);
    setInputVal('');
  };

  return (
    <div className="flex flex-col h-screen max-w-md mx-auto bg-[#F8FAFC]">
      {/* Top Header */}
      <div className="bg-white border-b border-slate-200/80 px-3 py-2.5 flex items-center justify-between sticky top-0 z-30 shadow-xs">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setCurrentScreen('chats')}
            className="p-1 -ml-1 text-slate-600 hover:text-slate-900 rounded-full hover:bg-slate-100 transition-colors"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>

          <div 
            onClick={() => setShowTransferKeyModal(true)}
            className="flex items-center gap-2.5 cursor-pointer group"
          >
            <div className="relative">
              <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-sky-600 to-indigo-600 p-[1.5px]">
                <img
                  src="https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=200&q=80"
                  alt="KINI Core Engineering"
                  className="w-full h-full rounded-full object-cover border border-white"
                  referrerPolicy="no-referrer"
                />
              </div>
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
            </div>

            <div>
              <div className="flex items-center gap-1">
                <h2 className="text-sm font-bold text-slate-900 group-hover:text-sky-600 transition-colors flex items-center gap-1">
                  <span>KINI Core Engineering</span>
                  <span className="text-sky-600 text-xs font-black">✓</span>
                </h2>
              </div>
              <p className="text-[11px] text-emerald-600 font-medium flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                <span>{language === 'vi' ? '9 thành viên trực tuyến' : '9 members online'}</span>
              </p>
            </div>
          </div>
        </div>

        {/* Action icons */}
        <div className="flex items-center gap-1 text-slate-600">
          <button
            onClick={() => startCall()}
            className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-slate-100 text-slate-700 hover:text-sky-600 transition-colors"
            title="Gọi thoại"
          >
            <Phone className="w-4 h-4" />
          </button>

          <button
            onClick={() => startCall()}
            className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-slate-100 text-slate-700 hover:text-sky-600 transition-colors"
            title="Gọi video HD"
          >
            <Video className="w-4 h-4" />
          </button>

          <button
            onClick={() => setShowTransferKeyModal(true)}
            className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-slate-100 text-slate-700 hover:text-sky-600 transition-colors"
            title="Cài đặt & Bàn giao Key nhóm"
          >
            <MoreVertical className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Pinned Announcement Banner */}
      {showPinned && (
        <div className="bg-sky-50 border-b border-sky-100 px-3.5 py-2 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-2 overflow-hidden">
            <div className="w-6 h-6 rounded-md bg-sky-100 flex items-center justify-center text-sky-700 shrink-0">
              <Pin className="w-3.5 h-3.5" />
            </div>
            <div className="truncate">
              <span className="text-[10px] font-bold text-sky-800 uppercase tracking-wider block">
                {language === 'vi' ? 'TIN NHẮN ĐÃ GHIM' : 'PINNED MESSAGE'}
              </span>
              <p className="text-xs text-slate-800 font-medium truncate">
                Lịch release KINI CHAT v2.4 vào thứ Sáu tuần này...
              </p>
            </div>
          </div>

          <button
            onClick={() => setShowPinned(false)}
            className="text-slate-400 hover:text-slate-700 p-1"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Messages Scrollable Stream */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg) => {
          const isMe = msg.senderRole === 'owner';

          return (
            <div key={msg.id} className="flex items-start gap-2.5">
              <img
                src={msg.avatar}
                alt={msg.senderName}
                className="w-9 h-9 rounded-full object-cover shrink-0 border border-slate-200"
                referrerPolicy="no-referrer"
              />

              <div className="flex-1 max-w-[85%] space-y-1">
                {/* Sender label and role badge */}
                <div className="flex items-center gap-1.5">
                  <span className="text-xs font-bold text-slate-800">
                    {msg.senderName}
                  </span>

                  {msg.roleTag && (
                    <span className={`text-[10px] px-1.5 py-0.2 rounded-full font-medium flex items-center gap-0.5 border ${
                      msg.roleTag.includes('Trưởng nhóm')
                        ? 'bg-amber-50 text-amber-800 border-amber-300'
                        : 'bg-blue-50 text-blue-700 border-blue-200'
                    }`}>
                      {msg.roleTag.includes('Trưởng nhóm') && <Key className="w-2.5 h-2.5" />}
                      <span>{msg.roleTag}</span>
                    </span>
                  )}
                </div>

                {/* Message Content Render by Type */}
                {msg.type === 'text' && (
                  <div className="bg-white rounded-2xl rounded-tl-sm p-3 border border-slate-200/80 shadow-xs text-xs text-slate-800 leading-relaxed space-y-2">
                    <p>{msg.content}</p>

                    <div className="flex items-center justify-between text-[10px] text-slate-400 pt-1">
                      <div className="flex items-center gap-1.5">
                        {msg.reactions?.map((r, i) => (
                          <span
                            key={i}
                            className="bg-slate-50 border border-slate-200 px-1.5 py-0.5 rounded-full flex items-center gap-1 text-[11px]"
                          >
                            <span>{r.emoji}</span>
                            <span className="font-semibold text-slate-700">{r.count}</span>
                          </span>
                        ))}
                      </div>
                      <span className="font-mono">{msg.timestamp}</span>
                    </div>
                  </div>
                )}

                {/* Media Grid View */}
                {msg.type === 'media_grid' && (
                  <div className="bg-white rounded-2xl rounded-tl-sm p-2 border border-slate-200 shadow-xs space-y-2">
                    <div className="grid grid-cols-2 gap-1.5 rounded-xl overflow-hidden">
                      {msg.mediaUrls?.map((url, idx) => (
                        <div key={idx} className="relative aspect-square bg-slate-100 overflow-hidden">
                          <img
                            src={url}
                            alt="Mockup preview"
                            className="w-full h-full object-cover hover:scale-105 transition-transform"
                            referrerPolicy="no-referrer"
                          />
                          {idx === 3 && (
                            <div className="absolute inset-0 bg-sky-900/60 backdrop-blur-xs flex items-center justify-center text-white font-bold text-lg">
                              +3
                            </div>
                          )}
                        </div>
                      ))}
                    </div>

                    <div className="flex items-center justify-between px-1 text-[11px] text-slate-600">
                      <span className="font-medium">{msg.mediaCaption}</span>
                      <span className="font-mono text-slate-400">{msg.timestamp}</span>
                    </div>
                  </div>
                )}

                {/* Voice Message Player */}
                {msg.type === 'voice' && (
                  <div className="bg-sky-700 text-white rounded-2xl rounded-tl-sm p-3 shadow-md shadow-sky-700/20 space-y-2">
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => setIsPlayingAudio(!isPlayingAudio)}
                        className="w-10 h-10 rounded-full bg-white text-sky-700 flex items-center justify-center hover:scale-105 active:scale-95 transition-transform shadow-xs"
                      >
                        {isPlayingAudio ? (
                          <Pause className="w-5 h-5 fill-current" />
                        ) : (
                          <Play className="w-5 h-5 fill-current ml-0.5" />
                        )}
                      </button>

                      {/* Animated Audio Waveform */}
                      <div className="flex-1 flex items-center gap-1 h-7">
                        {[40, 70, 30, 90, 60, 100, 50, 80, 45, 95, 65, 35, 75, 55, 90, 40, 70, 85].map((h, i) => (
                          <span
                            key={i}
                            style={{ height: isPlayingAudio ? `${Math.max(20, (h + (i % 3) * 20) % 100)}%` : `${h}%` }}
                            className={`w-1 rounded-full transition-all duration-150 ${
                              i < 8 ? 'bg-white' : 'bg-white/40'
                            }`}
                          />
                        ))}
                      </div>

                      <span className="text-[10px] font-bold bg-sky-800/80 px-2 py-1 rounded-md">
                        {msg.voiceSpeed || '1.5x'}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-[11px] text-sky-100 font-mono">
                      <span>{isPlayingAudio ? '0:48 / 1:15' : '0:42 / 1:15'}</span>
                      <span>{msg.timestamp} • Đã gửi</span>
                    </div>
                  </div>
                )}

                {/* Location Map View */}
                {msg.type === 'location' && msg.locationData && (
                  <div className="bg-white rounded-2xl rounded-tl-sm border border-slate-200 shadow-xs overflow-hidden">
                    {/* Simulated Map View of Hanoi */}
                    <div className="h-32 bg-slate-100 relative flex items-center justify-center overflow-hidden">
                      <div className="absolute inset-0 opacity-80 bg-[radial-gradient(#93c5fd_1px,transparent_1px)] [background-size:16px_16px]" />
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="w-32 h-1 bg-amber-300 transform -rotate-12" />
                        <div className="w-48 h-1 bg-sky-300 transform rotate-45" />
                        <div className="w-24 h-24 rounded-full border-2 border-sky-400/40" />
                      </div>

                      {/* Map Pin marker */}
                      <div className="relative z-10 flex flex-col items-center animate-bounce">
                        <div className="w-9 h-9 rounded-full bg-rose-600 text-white flex items-center justify-center shadow-lg shadow-rose-600/40">
                          <MapPin className="w-5 h-5 fill-current" />
                        </div>
                      </div>

                      <div className="absolute bottom-2 right-2 bg-white/90 backdrop-blur-xs px-2 py-0.5 rounded text-[10px] font-semibold text-slate-700">
                        Hanoi
                      </div>
                    </div>

                    <div className="p-3 space-y-1">
                      <h4 className="text-xs font-bold text-slate-900">
                        {msg.locationData.title}
                      </h4>
                      <p className="text-[11px] text-slate-500">
                        {msg.locationData.address} • {msg.locationData.distance}
                      </p>

                      <div className="pt-2 flex items-center justify-between border-t border-slate-100">
                        <button 
                          onClick={() => showToast('Mở Google Maps chỉ đường tới Văn phòng')}
                          className="text-xs font-bold text-sky-600 hover:text-sky-700 flex items-center gap-1"
                        >
                          <span>{language === 'vi' ? 'Chỉ đường ngay' : 'Get directions'}</span>
                          <ChevronRight className="w-3.5 h-3.5" />
                        </button>
                        <span className="text-[10px] font-mono text-slate-400">{msg.timestamp}</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Lock Notice Bar */}
      {groupSettings.onlyAdminChat && (
        <div className="bg-sky-50/90 border-t border-sky-100 px-4 py-2 flex items-center gap-2 text-xs text-sky-800">
          <Lock className="w-3.5 h-3.5 text-sky-600 shrink-0" />
          <span className="text-[11px] leading-tight">
            {language === 'vi'
              ? 'Chế độ khóa chat: Chỉ Trưởng nhóm và Phó nhóm mới có thể gửi tin nhắn trong nhóm này. Thành viên thông thường chỉ được xem.'
              : 'Admin-only mode: Only Group Owner and Deputy Admins can send messages.'}
          </span>
        </div>
      )}

      {/* Message Composer */}
      <div className="bg-white border-t border-slate-200/80 p-3">
        {canSendMessage ? (
          <form onSubmit={handleSend} className="flex items-center gap-2">
            <button
              type="button"
              className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full"
              title="Đính kèm file"
            >
              <Paperclip className="w-4 h-4" />
            </button>

            <div className="flex-1 relative flex items-center">
              <input
                type="text"
                value={inputVal}
                onChange={(e) => setInputVal(e.target.value)}
                placeholder={language === 'vi' ? 'Nhập tin nhắn E2EE...' : 'Type an E2EE message...'}
                className="w-full pl-3 pr-9 py-2 bg-slate-100 focus:bg-white rounded-xl border border-slate-200 focus:border-sky-500 focus:ring-2 focus:ring-sky-500/15 text-xs text-slate-800 outline-hidden transition-all"
              />
              <button
                type="button"
                className="absolute right-2.5 text-slate-400 hover:text-slate-600"
              >
                <Smile className="w-4 h-4" />
              </button>
            </div>

            <button
              type="button"
              className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full"
              title="Ghi âm giọng nói"
            >
              <Mic className="w-4 h-4" />
            </button>

            <button
              type="submit"
              disabled={!inputVal.trim()}
              className="w-9 h-9 rounded-xl bg-sky-700 hover:bg-sky-800 disabled:opacity-40 text-white flex items-center justify-center transition-all shadow-xs"
            >
              <Send className="w-4 h-4 ml-0.5" />
            </button>
          </form>
        ) : (
          <div className="py-2.5 px-4 bg-slate-100 rounded-xl text-center text-xs text-slate-500 font-medium flex items-center justify-center gap-2">
            <Lock className="w-3.5 h-3.5 text-slate-400" />
            <span>
              {language === 'vi'
                ? 'Cuộc trò chuyện đã bị giới hạn bởi Trưởng nhóm [Key chính]'
                : 'Chat is locked by Group Owner [Key chính]'}
            </span>
          </div>
        )}
      </div>
    </div>
  );
};
