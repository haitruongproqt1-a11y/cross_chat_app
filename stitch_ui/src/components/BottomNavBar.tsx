import React from 'react';
import { MessageSquare, Users, Radio, Newspaper, Settings } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ScreenType } from '../types';

export const BottomNavBar: React.FC = () => {
  const { currentScreen, setCurrentScreen, language, chats } = useApp();

  const totalUnread = chats.reduce((acc, c) => acc + (c.unreadCount || 0), 0);

  const tabs: { id: ScreenType; labelVi: string; labelEn: string; icon: React.ComponentType<{ className?: string }>; badge?: number; hasDot?: boolean; hasVnFlag?: boolean }[] = [
    {
      id: 'chats',
      labelVi: 'Tin nhắn',
      labelEn: 'Chats',
      icon: MessageSquare,
      badge: totalUnread > 0 ? totalUnread : undefined
    },
    {
      id: 'contacts',
      labelVi: 'Danh bạ',
      labelEn: 'Contacts',
      icon: Users
    },
    {
      id: 'radar',
      labelVi: 'Quanh đây',
      labelEn: 'Nearby',
      icon: Radio
    },
    {
      id: 'diary',
      labelVi: 'Nhật ký',
      labelEn: 'Diary',
      icon: Newspaper,
      hasDot: true
    },
    {
      id: 'settings',
      labelVi: 'Cài đặt',
      labelEn: 'Settings',
      icon: Settings,
      hasVnFlag: true
    }
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-slate-200/90 max-w-md mx-auto py-1 px-2 select-none shadow-lg shadow-slate-900/5">
      <div className="flex items-center justify-around">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = currentScreen === tab.id || (tab.id === 'chats' && currentScreen === 'chat_detail');

          return (
            <button
              key={tab.id}
              onClick={() => setCurrentScreen(tab.id)}
              className={`flex flex-col items-center justify-center py-1 px-3 relative transition-all duration-200 ${
                isActive ? 'text-sky-600 font-semibold' : 'text-slate-500 hover:text-slate-800 font-medium'
              }`}
            >
              <div className="relative mb-0.5">
                <Icon className={`w-5 h-5 transition-transform ${isActive ? 'scale-110 stroke-[2.3]' : 'stroke-[1.8]'}`} />

                {/* Number Badge */}
                {tab.badge && (
                  <span className="absolute -top-1.5 -right-2.5 min-w-[17px] h-[17px] px-1 bg-sky-600 text-white text-[10px] font-bold rounded-full flex items-center justify-center border-2 border-white shadow-xs">
                    {tab.badge}
                  </span>
                )}

                {/* Red unread dot */}
                {tab.hasDot && !tab.badge && (
                  <span className="absolute -top-0.5 -right-1 w-2 h-2 bg-rose-500 rounded-full border border-white"></span>
                )}

                {/* Vietnam flag badge on settings */}
                {tab.hasVnFlag && (
                  <span 
                    title="Tiếng Việt chuẩn hóa" 
                    className="absolute -bottom-1 -right-1 text-[9px] leading-none"
                  >
                    🇻🇳
                  </span>
                )}
              </div>

              <span className="text-[11px] tracking-tight">
                {language === 'vi' ? tab.labelVi : tab.labelEn}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
