import React, { useState } from 'react';
import { ShieldCheck, User, Key, Eye, EyeOff, Fingerprint, Lock, ShieldAlert, ArrowRight } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const LoginScreen: React.FC = () => {
  const { setCurrentScreen, language, showToast } = useApp();
  const [activeTab, setActiveTab] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('hoangnam@kinichat.vn');
  const [password, setPassword] = useState('••••••••••••••••');
  const [showPassword, setShowPassword] = useState(false);
  const [autoLogin, setAutoLogin] = useState(true);
  const [secretQuestion, setSecretQuestion] = useState('Biệt danh thời thơ ấu của bạn là gì?');
  const [secretAnswer, setSecretAnswer] = useState('Sóc Nhí 2010');

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    showToast(language === 'vi' ? 'Đăng nhập thành công! E2EE Token đã cấp.' : 'Login successful! E2EE Token granted.');
    setCurrentScreen('chats');
  };

  const handleBiometric = () => {
    showToast(language === 'vi' ? 'Xác thực Face ID / Vân tay thành công!' : 'Biometric authentication verified!');
    setCurrentScreen('chats');
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col justify-center items-center p-4 max-w-md mx-auto">
      {/* Brand Header */}
      <div className="text-center mb-6">
        <div className="relative inline-block mb-3">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-sky-600 via-sky-500 to-blue-600 flex items-center justify-center text-white shadow-lg shadow-sky-500/25">
            <svg viewBox="0 0 24 24" className="w-9 h-9 fill-current" aria-hidden="true">
              <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-6 9h-2v2h-2v-2H8V9h2V7h2v2h2v2z"/>
            </svg>
          </div>
          <span className="absolute -top-1 -right-1 w-4 h-4 bg-emerald-500 border-2 border-white rounded-full"></span>
        </div>

        <h1 className="text-2xl font-black tracking-tight text-slate-900">
          KINI CHAT
        </h1>
        <p className="text-xs text-slate-500 font-medium mt-1 flex items-center justify-center gap-1.5">
          <ShieldCheck className="w-3.5 h-3.5 text-sky-600" />
          <span>{language === 'vi' ? 'Nhắn tin siêu tốc • Mã hóa đầu cuối E2EE' : 'Ultra-fast messaging • E2EE Encrypted'}</span>
        </p>
      </div>

      {/* Auth Card */}
      <div className="w-full bg-white rounded-3xl p-6 shadow-xl shadow-slate-900/5 border border-slate-100 space-y-5">
        {/* Switcher Tab */}
        <div className="flex bg-slate-100 p-1 rounded-2xl">
          <button
            type="button"
            onClick={() => setActiveTab('login')}
            className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
              activeTab === 'login'
                ? 'bg-white text-sky-700 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Lock className="w-3.5 h-3.5" />
            <span>{language === 'vi' ? 'Đăng Nhập' : 'Sign In'}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('register')}
            className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
              activeTab === 'register'
                ? 'bg-white text-sky-700 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <User className="w-3.5 h-3.5" />
            <span>{language === 'vi' ? 'Đăng Ký Tài Khoản' : 'Register'}</span>
          </button>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          {/* Username / Email */}
          <div>
            <label className="block text-[11px] font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              {language === 'vi' ? 'Tên đăng nhập hoặc Email' : 'Username or Email'}
            </label>
            <div className="relative flex items-center">
              <User className="absolute left-3.5 w-4 h-4 text-sky-600" />
              <input
                type="text"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-10 pr-3 py-2.5 bg-sky-50/50 hover:bg-sky-50 focus:bg-white rounded-xl border border-sky-100 focus:border-sky-500 focus:ring-2 focus:ring-sky-500/20 text-xs font-medium text-slate-800 outline-hidden transition-all"
                placeholder="tenban@kinichat.vn"
              />
            </div>
          </div>

          {/* Password */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-[11px] font-bold text-slate-700 uppercase tracking-wider">
                {language === 'vi' ? 'Mật khẩu bảo mật' : 'Security Password'}
              </label>
              <button 
                type="button" 
                onClick={() => showToast('Mã khôi phục đã gửi tới email bảo mật')}
                className="text-[11px] font-medium text-sky-600 hover:underline"
              >
                {language === 'vi' ? 'Quên mật khẩu?' : 'Forgot password?'}
              </button>
            </div>
            <div className="relative flex items-center">
              <Key className="absolute left-3.5 w-4 h-4 text-sky-600" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-10 pr-10 py-2.5 bg-sky-50/50 hover:bg-sky-50 focus:bg-white rounded-xl border border-sky-100 focus:border-sky-500 focus:ring-2 focus:ring-sky-500/20 text-xs font-mono text-slate-800 outline-hidden transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 text-slate-400 hover:text-slate-700"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Auto login checkbox */}
          <div className="flex items-start gap-2.5 pt-1">
            <input
              type="checkbox"
              id="autoLogin"
              checked={autoLogin}
              onChange={(e) => setAutoLogin(e.target.checked)}
              className="mt-0.5 w-4 h-4 rounded text-sky-600 focus:ring-sky-500 border-slate-300 cursor-pointer"
            />
            <label htmlFor="autoLogin" className="text-xs text-slate-700 cursor-pointer select-none">
              <span className="font-semibold block text-slate-900">
                {language === 'vi' ? 'Tự động đăng nhập trên thiết bị này' : 'Auto sign-in on this device'}
              </span>
              <span className="text-[11px] text-slate-500 flex items-center gap-1 mt-0.5">
                <ShieldCheck className="w-3 h-3 text-emerald-600" />
                {language === 'vi' ? 'Lưu phiên an toàn bằng token sinh trắc học' : 'Secured session via biometric token'}
              </span>
            </label>
          </div>

          {/* Submit buttons */}
          <div className="flex items-center gap-2.5 pt-2">
            <button
              type="submit"
              className="flex-1 py-3 px-4 bg-sky-700 hover:bg-sky-800 active:scale-[0.98] text-white font-bold text-xs rounded-xl shadow-md shadow-sky-600/25 flex items-center justify-center gap-2 transition-all"
            >
              <span>{language === 'vi' ? 'Đăng Nhập Ngay' : 'Sign In Now'}</span>
              <ArrowRight className="w-4 h-4" />
            </button>

            <button
              type="button"
              onClick={handleBiometric}
              title="Xác thực sinh trắc học (Fingerprint / Face ID)"
              className="w-12 h-11 bg-sky-50 hover:bg-sky-100 text-sky-700 rounded-xl flex items-center justify-center border border-sky-200/60 hover:scale-105 active:scale-95 transition-all"
            >
              <Fingerprint className="w-6 h-6" />
            </button>
          </div>
        </form>

        {/* 2-Factor Argon2id Recovery Box */}
        <div className="bg-slate-50/90 rounded-2xl p-4 border border-slate-200/80 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <ShieldAlert className="w-4 h-4 text-sky-600" />
              <h2 className="text-xs font-bold text-slate-900">
                {language === 'vi' ? 'Bảo mật 2 lớp KINI' : 'KINI 2-Factor Security'}
              </h2>
            </div>
            <span className="text-[10px] font-semibold text-sky-700 bg-sky-100 px-2 py-0.5 rounded-full flex items-center gap-1 border border-sky-200">
              <Key className="w-2.5 h-2.5" />
              {language === 'vi' ? 'Cứu hộ Key' : 'Key Recovery'}
            </span>
          </div>

          <p className="text-[11px] text-slate-500 leading-relaxed">
            {language === 'vi'
              ? 'Thiết lập để dự phòng khi mất thiết bị xác thực hoặc cần ủy quyền Key Trưởng nhóm.'
              : 'Configured for recovery if device is lost or for Group Key delegation.'}
          </p>

          <div>
            <label className="block text-[10px] font-semibold text-slate-600 uppercase mb-1">
              {language === 'vi' ? 'Chọn câu hỏi bí mật khôi phục' : 'Select security question'}
            </label>
            <select
              value={secretQuestion}
              onChange={(e) => setSecretQuestion(e.target.value)}
              className="w-full py-2 px-3 bg-white text-xs text-slate-800 rounded-xl border border-slate-200 outline-hidden font-medium"
            >
              <option>Biệt danh thời thơ ấu của bạn là gì?</option>
              <option>Tên con thú cưng đầu tiên của bạn là gì?</option>
              <option>Thành phố nơi bạn tốt nghiệp đại học?</option>
            </select>
          </div>

          <div>
            <label className="block text-[10px] font-semibold text-slate-600 uppercase mb-1">
              {language === 'vi' ? 'Câu trả lời bảo mật' : 'Security answer'}
            </label>
            <input
              type="text"
              value={secretAnswer}
              onChange={(e) => setSecretAnswer(e.target.value)}
              className="w-full py-2 px-3 bg-white text-xs text-slate-800 rounded-xl border border-slate-200 outline-hidden font-medium"
            />
          </div>

          <div className="p-2.5 bg-emerald-50/80 rounded-xl border border-emerald-100 flex items-start gap-2 text-[10px] text-emerald-800 leading-normal">
            <Lock className="w-3.5 h-3.5 text-emerald-600 shrink-0 mt-0.5" />
            <span>
              {language === 'vi'
                ? 'Câu trả lời được băm mã hóa một chiều bằng chuẩn Argon2id trước khi gửi lên máy chủ.'
                : 'Answers are one-way hashed with Argon2id before transmission to secure servers.'}
            </span>
          </div>
        </div>
      </div>

      {/* Footer Info */}
      <div className="mt-5 text-center space-y-2">
        <p className="text-[11px] text-slate-500 max-w-xs mx-auto leading-relaxed">
          {language === 'vi' ? (
            <>
              Bằng việc tiếp tục, bạn đồng ý với{' '}
              <span className="text-sky-600 font-semibold cursor-pointer hover:underline">Điều khoản sử dụng</span> &{' '}
              <span className="text-sky-600 font-semibold cursor-pointer hover:underline">Chính sách quyền riêng tư KINI CHAT</span>
            </>
          ) : (
            <>
              By continuing, you agree to our{' '}
              <span className="text-sky-600 font-semibold cursor-pointer hover:underline">Terms of Service</span> &{' '}
              <span className="text-sky-600 font-semibold cursor-pointer hover:underline">Privacy Policy</span>
            </>
          )}
        </p>

        <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-slate-200/60 rounded-full text-[10px] font-semibold text-slate-700">
          <ShieldCheck className="w-3 h-3 text-emerald-600" />
          <span>{language === 'vi' ? 'Bảo mật cấp Ngân hàng & Viễn thông' : 'Bank & Telecom Grade Security'}</span>
        </div>
      </div>
    </div>
  );
};
