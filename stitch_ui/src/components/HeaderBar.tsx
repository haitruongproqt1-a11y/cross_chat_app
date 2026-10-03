import React from 'react';
import { Search, PlayCircle, Edit3, User, ShieldCheck } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { CURRENT_USER } from '../data/mockData';

interface HeaderBarProps {
  title?: string;
  subtitle?: string;
  showSearch?: boolean;
}

export const HeaderBar: React.FC<HeaderBarProps> = ({ 
  title = 'KINI CHAT', 
  subtitle = 'Đã kết nối bảo mật',
  showSearch = true 
}) => {
  const { setCurrentScreen, language, userRole, setUserRole } = useApp();

  return (
    <header className="sticky top-0 z-30 bg-[#F8FAFC]/95 backdrop-blur-md border-b border-slate-200/80 px-4 py-2.5 flex items-center justify-between transition-all">
      {/* Brand & Connection State */}
      <div 
        onClick={() => setCurrentScreen('chats')} 
        className="flex items-center gap-2.5 cursor-pointer group"
      >
        <div className="relative">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-sky-600 to-sky-400 flex items-center justify-center text-white shadow-sm shadow-sky-500/20 group-hover:scale-105 transition-transform">
            <svg viewBox="0 0 24 24" className="w-5 h-5 fill-current" aria-hidden="true">
              <path d="M12 2C6.48 2 2 6.03 2 11c0 2.87 1.5 5.43 3.86 7.04V22l4.1-2.25c.66.16 1.34.25 2.04.25 5.52 0 10-4.03 10-9s-4.48-9-10-9zm1 12.5h-2v-2h2v2zm0-4h-2V6h2v4.5z"/>
            </svg>
          </div>
          {/* Active online green dot */}
          <span className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
        </div>

        <div>
          <div className="flex items-center gap-1.5">
            <h1 className="text-base font-bold tracking-tight text-slate-900 group-hover:text-sky-600 transition-colors">
              {title}
            </h1>
            <span className="inline-flex items-center px-1.5 py-0.2 text-[10px] font-semibold bg-sky-50 text-sky-700 rounded border border-sky-200/60">
              v2.4
            </span>
          </div>
          <div className="flex items-center gap-1 text-[11px] text-slate-500">
            <ShieldCheck className="w-3 h-3 text-emerald-600" />
            <span className="truncate">{language === 'vi' ? subtitle : 'E2EE Secured'}</span>
          </div>
        </div>
      </div>

      {/* Action buttons */}
      <div className="flex items-center gap-1">
        {/* Role toggle simulator button */}
        <button
          onClick={() => setUserRole(userRole === 'owner' ? 'deputy' : userRole === 'deputy' ? 'member' : 'owner')}
          title="Đổi quyền người dùng thử nghiệm (Trưởng / Phó / Thành viên)"
          className="text-[11px] font-medium px-2 py-1 rounded-md border flex items-center gap-1 transition-all mr-1 bg-white hover:bg-slate-50"
          style={{
            borderColor: userRole === 'owner' ? '#F59E0B' : userRole === 'deputy' ? '#3B82F6' : '#94A3B8',
            color: userRole === 'owner' ? '#B45309' : userRole === 'deputy' ? '#1D4ED8' : '#475569'
          }}
        >
          <span>{userRole === 'owner' ? '🔑 Key chính' : userRole === 'deputy' ? '🛡️ Phó nhóm' : '👤 Thành viên'}</span>
        </button>

        <button 
          onClick={() => setCurrentScreen('radar')}
          aria-label="Khám phá radar"
          className="w-8 h-8 rounded-full flex items-center justify-center text-slate-600 hover:text-sky-600 hover:bg-slate-100 transition-colors"
        >
          <PlayCircle className="w-4 h-4" />
        </button>

        <button 
          onClick={() => setCurrentScreen('diary')}
          aria-label="Đăng nhật ký"
          className="w-8 h-8 rounded-full flex items-center justify-center text-slate-600 hover:text-sky-600 hover:bg-slate-100 transition-colors"
        >
          <Edit3 className="w-4 h-4" />
        </button>

        <button 
          onClick={() => setCurrentScreen('settings')}
          aria-label="Trang cá nhân & Cài đặt"
          className="w-8 h-8 rounded-full flex items-center justify-center text-slate-600 hover:text-sky-600 hover:bg-slate-100 transition-colors ml-0.5"
        >
          <div className="w-7 h-7 rounded-full overflow-hidden border border-slate-200">
            <img 
              src={CURRENT_USER.avatar} 
              alt={CURRENT_USER.name} 
              className="w-full h-full object-cover"
              referrerPolicy="no-referrer"
            />
          </div>
        </button>
      </div>
    </header>
  );
};
