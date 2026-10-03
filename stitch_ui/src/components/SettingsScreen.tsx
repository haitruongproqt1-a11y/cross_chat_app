import React, { useState } from 'react';
import { 
  ShieldCheck, QrCode, Globe, Check, Palette, ChevronRight, 
  Lock, Fingerprint, Smartphone, RefreshCw, LogOut, Shield, Key
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { CURRENT_USER, THEME_BUBBLES } from '../data/mockData';

export const SettingsScreen: React.FC = () => {
  const { 
    language, 
    setLanguage, 
    selectedTheme, 
    setSelectedTheme, 
    setCurrentScreen, 
    showToast 
  } = useApp();

  const [faceIdEnabled, setFaceIdEnabled] = useState(true);
  const [autoLoginEnabled, setAutoLoginEnabled] = useState(true);

  const handleLogout = () => {
    showToast(language === 'vi' ? 'Đã đăng xuất tài khoản an toàn' : 'Logged out securely');
    setCurrentScreen('login');
  };

  return (
    <div className="pb-24 max-w-md mx-auto min-h-screen bg-[#F8FAFC]">
      {/* Profile Summary Card */}
      <div className="p-4">
        <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center gap-3.5">
            <div className="relative">
              <img
                src={CURRENT_USER.avatar}
                alt={CURRENT_USER.name}
                className="w-16 h-16 rounded-full object-cover border-2 border-slate-100"
                referrerPolicy="no-referrer"
              />
              <span className="absolute bottom-0 right-0 w-4 h-4 bg-sky-600 rounded-full border-2 border-white flex items-center justify-center text-white text-[9px] font-bold">
                ✓
              </span>
            </div>

            <div className="flex-1 min-w-0">
              <h2 className="text-base font-black text-slate-900 truncate">
                {CURRENT_USER.name}
              </h2>
              <p className="text-xs text-slate-500 font-medium truncate">
                {CURRENT_USER.handle} • {CURRENT_USER.phone}
              </p>
              <div className="mt-1 inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-50 text-emerald-800 text-[10px] font-bold rounded-full border border-emerald-200/60">
                <ShieldCheck className="w-3 h-3 text-emerald-600" />
                <span>{language === 'vi' ? 'Tài khoản Pro Đã xác thực E2EE' : 'Verified Pro E2EE Account'}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 pt-1">
            <button
              onClick={() => showToast('Chỉnh sửa thông tin tài khoản')}
              className="flex-1 py-2 px-3 bg-sky-50 hover:bg-sky-100 text-sky-700 font-bold text-xs rounded-xl transition-colors flex items-center justify-center gap-1.5"
            >
              <span>{language === 'vi' ? 'Chỉnh sửa hồ sơ' : 'Edit profile'}</span>
            </button>

            <button
              onClick={() => showToast('Mã QR cá nhân KINI CHAT')}
              className="p-2 bg-sky-50 hover:bg-sky-100 text-sky-700 rounded-xl transition-colors"
              title="Mã QR cá nhân"
            >
              <QrCode className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Section 1: Language & Region */}
      <div className="px-4 pb-3">
        <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Globe className="w-4 h-4 text-sky-600" />
              <h3 className="text-xs font-bold text-slate-900">
                Ngôn ngữ & Khu vực / Language & Region
              </h3>
            </div>
            <span className="text-[10px] font-bold text-sky-700 bg-sky-100 px-2 py-0.5 rounded-full">
              {language === 'vi' ? 'Tức thì' : 'Instant'}
            </span>
          </div>

          <div className="space-y-2">
            {/* Vietnamese Radio */}
            <div
              onClick={() => {
                setLanguage('vi');
                showToast('Đã đổi ngôn ngữ sang Tiếng Việt');
              }}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                language === 'vi'
                  ? 'bg-sky-50/80 border-sky-300 ring-1 ring-sky-300/40'
                  : 'bg-white border-slate-200 hover:bg-slate-50'
              }`}
            >
              <div className="flex items-start gap-3">
                <span className="text-2xl leading-none">🇻🇳</span>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">Tiếng Việt</h4>
                  <p className="text-[11px] text-slate-500 mt-0.5 leading-snug">
                    Tiếng Việt (Mặc định • Giao diện hoàn toàn bằng tiếng Việt chuẩn hóa)
                  </p>
                </div>
              </div>

              {language === 'vi' ? (
                <div className="w-5 h-5 rounded-full bg-sky-600 text-white flex items-center justify-center shrink-0">
                  <Check className="w-3.5 h-3.5 stroke-[3]" />
                </div>
              ) : (
                <div className="w-5 h-5 rounded-full border-2 border-slate-300 shrink-0"></div>
              )}
            </div>

            {/* English Radio */}
            <div
              onClick={() => {
                setLanguage('en');
                showToast('Language switched to English');
              }}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                language === 'en'
                  ? 'bg-sky-50/80 border-sky-300 ring-1 ring-sky-300/40'
                  : 'bg-white border-slate-200 hover:bg-slate-50'
              }`}
            >
              <div className="flex items-start gap-3">
                <span className="text-2xl leading-none">🇬🇧</span>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">English</h4>
                  <p className="text-[11px] text-slate-500 mt-0.5 leading-snug">
                    Switch all UI labels, system alerts, and chats into pure English
                  </p>
                </div>
              </div>

              {language === 'en' ? (
                <div className="w-5 h-5 rounded-full bg-sky-600 text-white flex items-center justify-center shrink-0">
                  <Check className="w-3.5 h-3.5 stroke-[3]" />
                </div>
              ) : (
                <div className="w-5 h-5 rounded-full border-2 border-slate-300 shrink-0"></div>
              )}
            </div>
          </div>

          <div className="p-2.5 bg-emerald-50/70 border border-emerald-100 rounded-xl text-[10px] text-emerald-800 flex items-center gap-1.5">
            <span className="font-bold">⚡</span>
            <span>
              {language === 'vi'
                ? 'Hệ thống sẽ cập nhật ngôn ngữ ngay lập tức mà không cần khởi động lại ứng dụng.'
                : 'Language changes apply immediately across all screens without reloading.'}
            </span>
          </div>
        </div>
      </div>

      {/* Section 2: Chat Bubbles Themes */}
      <div className="px-4 pb-3">
        <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Palette className="w-4 h-4 text-sky-600" />
              <h3 className="text-xs font-bold text-slate-900">
                {language === 'vi' ? 'Kho Bong Bóng Chat & Cá Nhân Hóa' : 'Chat Bubbles & Customization'}
              </h3>
            </div>
            <span className="text-[10px] font-bold text-slate-500">
              20 {language === 'vi' ? 'chủ đề' : 'themes'}
            </span>
          </div>

          <div className="grid grid-cols-3 gap-2">
            {THEME_BUBBLES.slice(0, 3).map((theme) => {
              const isSelected = selectedTheme === theme.id;

              return (
                <div
                  key={theme.id}
                  onClick={() => {
                    setSelectedTheme(theme.id);
                    showToast(language === 'vi' ? `Đã áp dụng chủ đề: ${theme.name}` : `Theme applied: ${theme.name}`);
                  }}
                  className={`p-2.5 rounded-2xl border transition-all cursor-pointer flex flex-col justify-between ${
                    isSelected
                      ? 'bg-sky-50/80 border-sky-400 ring-1 ring-sky-300'
                      : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <div>
                    <div className="flex items-center justify-between text-[11px] font-bold text-slate-800 mb-1.5">
                      <span className="truncate">{theme.name}</span>
                      <span>{theme.icon}</span>
                    </div>

                    <div
                      style={{ backgroundColor: isSelected ? '#E0F2FE' : '#F1F5F9' }}
                      className="px-2 py-1 rounded-lg text-[10px] font-medium text-slate-700 truncate"
                    >
                      {theme.preview}
                    </div>
                  </div>

                  <span className="mt-2 text-[9px] font-bold text-center block" style={{ color: isSelected ? '#0369A1' : '#64748B' }}>
                    {isSelected ? (language === 'vi' ? '✓ Đang áp dụng' : '✓ Applied') : (language === 'vi' ? 'Chọn thử' : 'Try')}
                  </span>
                </div>
              );
            })}
          </div>

          {/* Chat wallpaper customizer */}
          <button
            onClick={() => showToast('Mở bộ sưu tập hình nền cuộc trò chuyện')}
            className="w-full flex items-center justify-between p-3 bg-slate-50 hover:bg-slate-100 rounded-2xl border border-slate-100 transition-colors text-left"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600">
                <Palette className="w-4 h-4" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-900">
                  {language === 'vi' ? 'Hình nền cuộc trò chuyện' : 'Chat Wallpaper'}
                </h4>
                <p className="text-[11px] text-slate-500">
                  {language === 'vi' ? 'Màu gradient phấn dịu • Tùy chỉnh riêng' : 'Soft pastel gradient • Customizable'}
                </p>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </button>
        </div>
      </div>

      {/* Section 3: Security & Privacy */}
      <div className="px-4 pb-3">
        <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-sky-600" />
            <h3 className="text-xs font-bold text-slate-900">
              {language === 'vi' ? 'Bảo Mật & Quyền Riêng Tư' : 'Security & Privacy'}
            </h3>
          </div>

          <div className="space-y-3 divide-y divide-slate-100">
            {/* Key Group Management */}
            <div 
              onClick={() => showToast('Mở trung tâm quản lý mã khóa E2EE')}
              className="flex items-center justify-between pt-1 cursor-pointer group"
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-sky-50 flex items-center justify-center text-sky-600">
                  <Key className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-slate-900 group-hover:text-sky-600 transition-colors flex items-center gap-1.5">
                    <span>{language === 'vi' ? 'Quản lý khóa Key nhóm' : 'Group Keys Management'}</span>
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  </h4>
                  <p className="text-[11px] text-slate-500">
                    {language === 'vi' ? '3 nhóm Key chính • 2 nhóm Key phụ' : '3 Owner Keys • 2 Deputy Keys'}
                  </p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

            {/* Face ID / Fingerprint */}
            <div className="flex items-center justify-between pt-3">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-sky-50 flex items-center justify-center text-sky-600">
                  <Fingerprint className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">
                    {language === 'vi' ? 'Xác thực Face ID / Vân tay' : 'Face ID / Fingerprint'}
                  </h4>
                  <p className="text-[11px] text-slate-500">
                    {language === 'vi' ? 'Yêu cầu mở khóa khi truy cập tin nhắn' : 'Require unlock when opening app'}
                  </p>
                </div>
              </div>

              <button
                onClick={() => setFaceIdEnabled(!faceIdEnabled)}
                className={`w-11 h-6 rounded-full transition-colors relative p-0.5 shrink-0 ${
                  faceIdEnabled ? 'bg-sky-700' : 'bg-slate-300'
                }`}
              >
                <div
                  className={`w-5 h-5 rounded-full bg-white shadow-xs transform transition-transform ${
                    faceIdEnabled ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            {/* Auto Login Device */}
            <div className="flex items-center justify-between pt-3">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-sky-50 flex items-center justify-center text-sky-600">
                  <Smartphone className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">
                    {language === 'vi' ? 'Tự động đăng nhập' : 'Auto Sign-in'}
                  </h4>
                  <p className="text-[11px] text-slate-500">
                    {language === 'vi' ? 'Thiết bị hiện tại: iPhone 15 Pro Max' : 'Current device: iPhone 15 Pro Max'}
                  </p>
                </div>
              </div>

              <button
                onClick={() => setAutoLoginEnabled(!autoLoginEnabled)}
                className={`w-11 h-6 rounded-full transition-colors relative p-0.5 shrink-0 ${
                  autoLoginEnabled ? 'bg-sky-700' : 'bg-slate-300'
                }`}
              >
                <div
                  className={`w-5 h-5 rounded-full bg-white shadow-xs transform transition-transform ${
                    autoLoginEnabled ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Section 4: App update info */}
      <div className="px-4 pb-4">
        <div className="bg-white rounded-3xl p-4 border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-sky-50 flex items-center justify-center text-sky-600">
              <RefreshCw className="w-4 h-4" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-slate-900">
                {language === 'vi' ? 'Kiểm tra bản cập nhật' : 'Check for updates'}
              </h4>
              <p className="text-[11px] text-slate-500 font-mono">
                KINI CHAT v2.4.0 ({language === 'vi' ? 'Bản mới nhất' : 'Latest'})
              </p>
            </div>
          </div>

          <span className="text-[11px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
            {language === 'vi' ? 'Mới nhất' : 'Up to date'}
          </span>
        </div>
      </div>

      {/* Logout Button */}
      <div className="px-4 pb-6 space-y-2">
        <button
          onClick={handleLogout}
          className="w-full py-3.5 px-4 bg-rose-700 hover:bg-rose-800 active:scale-[0.98] text-white font-bold text-xs rounded-2xl shadow-md shadow-rose-700/20 flex items-center justify-center gap-2 transition-all"
        >
          <LogOut className="w-4 h-4" />
          <span>{language === 'vi' ? 'Đăng xuất tài khoản' : 'Sign Out Account'}</span>
        </button>

        <p className="text-[11px] text-slate-400 text-center leading-normal">
          {language === 'vi'
            ? 'Hành động này sẽ xóa phiên tự động đăng nhập trên thiết bị này.'
            : 'This will revoke active biometric sessions on this device.'}
        </p>
      </div>
    </div>
  );
};
