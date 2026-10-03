import React, { useState } from 'react';
import { 
  ChevronDown, UserPlus, Shield, Mic, MicOff, Video, VideoOff, 
  Share2, Wand2, PhoneOff, RefreshCw, Volume2
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { CURRENT_USER } from '../data/mockData';

export const VideoCallScreen: React.FC = () => {
  const { 
    endCall, 
    callDuration, 
    isCallMuted, 
    toggleCallMute, 
    isCallCamOff, 
    toggleCallCam, 
    isSharingScreen, 
    toggleScreenShare,
    language,
    showToast 
  } = useApp();

  const [reactions, setReactions] = useState<{ id: number; emoji: string; x: number }[]>([]);

  const formatCallTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const triggerReaction = (emoji: string) => {
    const id = Date.now();
    const x = Math.random() * 60 - 30;
    setReactions(prev => [...prev, { id, emoji, x }]);
    setTimeout(() => {
      setReactions(prev => prev.filter(r => r.id !== id));
    }, 2000);
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950 flex flex-col justify-between max-w-md mx-auto overflow-hidden select-none">
      {/* Fullscreen Video Background */}
      <div className="absolute inset-0 z-0">
        <img
          src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=800&q=80"
          alt="Linh Trần Video Call"
          className="w-full h-full object-cover brightness-95"
          referrerPolicy="no-referrer"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-transparent to-black/80" />
      </div>

      {/* Floating Animated Reaction Emojis */}
      <div className="absolute inset-0 pointer-events-none z-30 overflow-hidden">
        {reactions.map((r) => (
          <div
            key={r.id}
            style={{ transform: `translateX(${r.x}px)` }}
            className="absolute bottom-32 right-12 text-3xl animate-in fade-in slide-out-to-top duration-1000"
          >
            {r.emoji}
          </div>
        ))}
      </div>

      {/* Top Bar Header */}
      <div className="relative z-20 p-4 pt-6 space-y-4">
        <div className="flex items-center justify-between">
          <button
            onClick={endCall}
            className="w-9 h-9 rounded-full bg-black/40 backdrop-blur-md text-white flex items-center justify-center hover:bg-black/60 transition-colors"
          >
            <ChevronDown className="w-5 h-5" />
          </button>

          {/* Call Status & Encryption Pill */}
          <div className="flex items-center gap-2 px-3.5 py-1.5 bg-black/40 backdrop-blur-md rounded-full border border-white/10 text-white text-xs font-mono">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>{formatCallTime(callDuration)}</span>
            <span className="text-white/40">•</span>
            <div className="flex items-center gap-1 text-[11px] text-emerald-400 font-sans font-semibold">
              <Shield className="w-3 h-3 text-emerald-400" />
              <span>E2EE</span>
            </div>
          </div>

          <button 
            onClick={() => showToast('Mời thêm thành viên vào cuộc gọi')}
            className="w-9 h-9 rounded-full bg-black/40 backdrop-blur-md text-white flex items-center justify-center hover:bg-black/60 transition-colors"
          >
            <UserPlus className="w-4 h-4" />
          </button>
        </div>

        {/* Callee Info */}
        <div className="flex items-start justify-between">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <h2 className="text-2xl font-bold text-white tracking-tight drop-shadow-md">
                Linh Trần
              </h2>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-sky-500/80 backdrop-blur-md text-white text-[11px] font-bold rounded-full border border-sky-300/40">
                <Shield className="w-3 h-3" />
                <span>Phó nhóm</span>
              </span>
            </div>

            <p className="text-xs text-emerald-400 font-medium flex items-center gap-1.5 drop-shadow-sm">
              <span className="inline-block w-1.5 h-3 bg-emerald-500 rounded-xs"></span>
              <span>HD Audio & Video 5G • 60 FPS</span>
            </p>
          </div>

          {/* User PiP Window */}
          <div className="relative w-24 h-36 rounded-2xl overflow-hidden border-2 border-white/80 shadow-2xl bg-slate-900 group">
            {isCallCamOff ? (
              <div className="w-full h-full flex flex-col items-center justify-center text-white/60 bg-slate-800">
                <VideoOff className="w-6 h-6 mb-1" />
                <span className="text-[10px]">Cam Tắt</span>
              </div>
            ) : (
              <img
                src={CURRENT_USER.avatar}
                alt="Bạn"
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
            )}
            <div className="absolute top-1.5 right-1.5 w-6 h-6 rounded-full bg-black/50 backdrop-blur-xs flex items-center justify-center text-white">
              <RefreshCw className="w-3 h-3" />
            </div>
            <div className="absolute bottom-1.5 left-2 flex items-center gap-1 text-[10px] text-white font-semibold drop-shadow-xs">
              <span>Bạn</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
            </div>
          </div>
        </div>

        {/* Screen Sharing Banner */}
        {isSharingScreen && (
          <div className="bg-slate-900/80 backdrop-blur-md border border-white/10 rounded-2xl p-2.5 flex items-center gap-2.5 text-white shadow-lg">
            <div className="w-8 h-8 rounded-xl bg-sky-600 flex items-center justify-center text-white shrink-0">
              <Share2 className="w-4 h-4" />
            </div>
            <div className="truncate">
              <span className="text-[10px] font-bold text-emerald-400 uppercase tracking-wider block">
                {language === 'vi' ? 'ĐANG CHIA SẺ MÀN HÌNH' : 'SHARING SCREEN'}
              </span>
              <p className="text-xs font-semibold text-white truncate">
                KINI_Sprint_Review_Final.pdf
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Floating Reaction Buttons on Right Side */}
      <div className="absolute right-4 bottom-28 z-20 flex flex-col gap-2.5">
        <button
          onClick={() => triggerReaction('❤️')}
          className="w-10 h-10 rounded-full bg-slate-900/60 backdrop-blur-md hover:bg-slate-900/90 text-white flex items-center justify-center text-lg shadow-lg active:scale-125 transition-transform"
        >
          ❤️
        </button>
        <button
          onClick={() => triggerReaction('👏')}
          className="w-10 h-10 rounded-full bg-slate-900/60 backdrop-blur-md hover:bg-slate-900/90 text-white flex items-center justify-center text-lg shadow-lg active:scale-125 transition-transform"
        >
          👏
        </button>
        <button
          onClick={() => triggerReaction('🎉')}
          className="w-10 h-10 rounded-full bg-slate-900/60 backdrop-blur-md hover:bg-slate-900/90 text-white flex items-center justify-center text-lg shadow-lg active:scale-125 transition-transform"
        >
          🎉
        </button>
      </div>

      {/* Active Speaker Wave Pill */}
      <div className="relative z-20 flex justify-center mb-3">
        <div className="px-4 py-1.5 bg-black/50 backdrop-blur-md rounded-full border border-white/15 text-white text-xs font-medium flex items-center gap-2 shadow-lg">
          <Volume2 className="w-3.5 h-3.5 text-emerald-400" />
          <span>Linh đang nói...</span>
          <div className="flex items-center gap-0.5">
            <span className="w-1 h-3 bg-emerald-400 rounded-full animate-bounce"></span>
            <span className="w-1 h-4 bg-emerald-400 rounded-full animate-bounce [animation-delay:0.15s]"></span>
            <span className="w-1 h-2 bg-emerald-400 rounded-full animate-bounce [animation-delay:0.3s]"></span>
          </div>
        </div>
      </div>

      {/* Bottom Control Dock */}
      <div className="relative z-20 bg-slate-900/90 backdrop-blur-xl border-t border-white/10 p-4 pt-3 pb-6 flex items-center justify-around">
        {/* Toggle Mic */}
        <button
          onClick={toggleCallMute}
          className="flex flex-col items-center gap-1 text-white group"
        >
          <div className={`w-12 h-12 rounded-full flex items-center justify-center transition-colors ${
            isCallMuted ? 'bg-rose-500 text-white' : 'bg-white/15 hover:bg-white/25 text-white'
          }`}>
            {isCallMuted ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
          </div>
          <span className="text-[10px] text-white/80 font-medium">
            {isCallMuted ? (language === 'vi' ? 'Bật mic' : 'Unmute') : (language === 'vi' ? 'Tắt mic' : 'Mute')}
          </span>
        </button>

        {/* Toggle Camera */}
        <button
          onClick={toggleCallCam}
          className="flex flex-col items-center gap-1 text-white group"
        >
          <div className={`w-12 h-12 rounded-full flex items-center justify-center transition-colors ${
            isCallCamOff ? 'bg-rose-500 text-white' : 'bg-white/15 hover:bg-white/25 text-white'
          }`}>
            {isCallCamOff ? <VideoOff className="w-5 h-5" /> : <Video className="w-5 h-5" />}
          </div>
          <span className="text-[10px] text-white/80 font-medium">
            {isCallCamOff ? (language === 'vi' ? 'Bật cam' : 'Start Cam') : (language === 'vi' ? 'Tắt cam' : 'Stop Cam')}
          </span>
        </button>

        {/* Share Screen */}
        <button
          onClick={toggleScreenShare}
          className="flex flex-col items-center gap-1 text-white group"
        >
          <div className={`w-12 h-12 rounded-full flex items-center justify-center transition-colors ${
            isSharingScreen ? 'bg-sky-600 text-white' : 'bg-white/15 hover:bg-white/25 text-white'
          }`}>
            <Share2 className="w-5 h-5" />
          </div>
          <span className="text-[10px] text-white/80 font-medium">
            {language === 'vi' ? 'Chia sẻ' : 'Share'}
          </span>
        </button>

        {/* Effects */}
        <button
          onClick={() => showToast('Đang áp dụng bộ lọc ánh sáng studio')}
          className="flex flex-col items-center gap-1 text-white group"
        >
          <div className="w-12 h-12 rounded-full bg-white/15 hover:bg-white/25 text-white flex items-center justify-center transition-colors">
            <Wand2 className="w-5 h-5" />
          </div>
          <span className="text-[10px] text-white/80 font-medium">
            {language === 'vi' ? 'Hiệu ứng' : 'Effects'}
          </span>
        </button>

        {/* End Call Button */}
        <button
          onClick={endCall}
          className="flex flex-col items-center gap-1 text-white group"
        >
          <div className="w-12 h-12 rounded-full bg-rose-600 hover:bg-rose-700 active:scale-95 text-white flex items-center justify-center shadow-lg shadow-rose-600/40 transition-transform">
            <PhoneOff className="w-6 h-6" />
          </div>
          <span className="text-[10px] text-rose-300 font-bold">
            {language === 'vi' ? 'Kết thúc' : 'End'}
          </span>
        </button>
      </div>
    </div>
  );
};
