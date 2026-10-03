import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { 
  MessageSquare, Radio, Video, Newspaper, Settings, 
  Lock, RefreshCw, Layers, ChevronUp, ChevronDown, CheckCircle2 
} from 'lucide-react';
import { INITIAL_CHATS } from '../data/mockData';

export const QuickScreenSwitcher: React.FC = () => {
  const { 
    currentScreen, 
    setCurrentScreen, 
    setActiveSheetContact, 
    setShowTransferKeyModal, 
    startCall, 
    userRole, 
    setUserRole,
    language,
    setLanguage 
  } = useApp();

  const [isOpen, setIsOpen] = useState(false);

  const screens = [
    {
      id: 'chats',
      label: 'Image 1: Chat List',
      sub: 'Vuốt Ghim/Xóa & Action Sheet',
      action: () => setCurrentScreen('chats'),
      active: currentScreen === 'chats'
    },
    {
      id: 'sheet',
      label: 'Image 1: Bottom Sheet',
      sub: 'Menu Thu Hà (Ghim, Xóa, Tắt)',
      action: () => {
        setCurrentScreen('chats');
        setActiveSheetContact(INITIAL_CHATS[2]); // Thu Hà
      },
      active: false
    },
    {
      id: 'login',
      label: 'Image 3: Đăng Nhập E2EE',
      sub: 'Khôi phục Argon2id & Vân tay',
      action: () => setCurrentScreen('login'),
      active: currentScreen === 'login'
    },
    {
      id: 'radar',
      label: 'Image 5: Radar Quanh Đây',
      sub: 'Quét GPS, Lân cận & Bộ lọc',
      action: () => setCurrentScreen('radar'),
      active: currentScreen === 'radar'
    },
    {
      id: 'chat_detail',
      label: 'Image 7: Chat Nhóm Lõi',
      sub: 'Khóa chat, Ghi âm & Bản đồ',
      action: () => setCurrentScreen('chat_detail'),
      active: currentScreen === 'chat_detail'
    },
    {
      id: 'diary',
      label: 'Image 9: Nhật Ký Tường Nhà',
      sub: 'Hồ Tây, Bài đăng & Bình luận',
      action: () => setCurrentScreen('diary'),
      active: currentScreen === 'diary'
    },
    {
      id: 'call',
      label: 'Image 11: Video Call HD',
      sub: 'Linh Trần, Chia sẻ màn hình',
      action: () => startCall(),
      active: currentScreen === 'call'
    },
    {
      id: 'settings',
      label: 'Image 13: Cài Đặt',
      sub: 'Chuyển ngữ VI/EN & Bong bóng',
      action: () => setCurrentScreen('settings'),
      active: currentScreen === 'settings'
    },
    {
      id: 'transfer',
      label: 'Image 17: Bàn Giao Key',
      sub: 'Xác nhận rời nhóm & Trao Key',
      action: () => {
        setCurrentScreen('chat_detail');
        setShowTransferKeyModal(true);
      },
      active: false
    }
  ];

  return (
    <div className="fixed top-2 right-2 z-50 select-none">
      <div className="flex flex-col items-end">
        {/* Toggle Button */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-900/90 hover:bg-slate-900 text-white rounded-full shadow-lg backdrop-blur-md text-[11px] font-bold border border-white/20 transition-all hover:scale-105 active:scale-95"
        >
          <Layers className="w-3.5 h-3.5 text-sky-400" />
          <span>Màn Hình ({screens.length})</span>
          {isOpen ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
        </button>

        {/* Dropdown Menu */}
        {isOpen && (
          <div className="mt-2 w-72 bg-white/98 backdrop-blur-xl rounded-2xl shadow-2xl border border-slate-200/90 p-3 space-y-2 animate-in fade-in zoom-in-95 text-slate-800">
            <div className="flex items-center justify-between pb-1.5 border-b border-slate-100">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Chọn màn hình trong ảnh
              </span>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setLanguage(language === 'vi' ? 'en' : 'vi')}
                  className="px-1.5 py-0.5 bg-slate-100 hover:bg-slate-200 rounded text-[10px] font-bold text-sky-700"
                >
                  {language === 'vi' ? 'VI 🇻🇳' : 'EN 🇬🇧'}
                </button>
              </div>
            </div>

            <div className="max-h-80 overflow-y-auto space-y-1 pr-1 divide-y divide-slate-100">
              {screens.map((item, idx) => (
                <button
                  key={idx}
                  onClick={() => {
                    item.action();
                    setIsOpen(false);
                  }}
                  className={`w-full text-left p-2 rounded-xl transition-all flex items-center justify-between ${
                    item.active
                      ? 'bg-sky-50 text-sky-900 font-bold border border-sky-200'
                      : 'hover:bg-slate-50 text-slate-700'
                  }`}
                >
                  <div className="min-w-0 pr-2">
                    <p className="text-xs truncate">{item.label}</p>
                    <p className="text-[10px] text-slate-500 truncate">{item.sub}</p>
                  </div>
                  {item.active && (
                    <CheckCircle2 className="w-3.5 h-3.5 text-sky-600 shrink-0" />
                  )}
                </button>
              ))}
            </div>

            {/* Quick role simulator */}
            <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[11px]">
              <span className="text-slate-500 font-medium">Quyền:</span>
              <div className="flex items-center gap-1">
                {(['owner', 'deputy', 'member'] as const).map(role => (
                  <button
                    key={role}
                    onClick={() => setUserRole(role)}
                    className={`px-2 py-0.5 rounded text-[10px] font-semibold border ${
                      userRole === role
                        ? 'bg-sky-600 text-white border-sky-600'
                        : 'bg-slate-50 text-slate-600 border-slate-200'
                    }`}
                  >
                    {role === 'owner' ? 'Trưởng' : role === 'deputy' ? 'Phó' : 'Thường'}
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
