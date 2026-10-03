import React, { useState } from 'react';
import { 
  RefreshCw, Shield, AlertCircle, ChevronDown, UserPlus, Search, 
  Palette, BellOff, Edit2, X, Check
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const TransferKeyModal: React.FC = () => {
  const { 
    showTransferKeyModal, 
    setShowTransferKeyModal, 
    groupSettings, 
    updateGroupSettings, 
    setUserRole,
    language,
    showToast,
    setCurrentScreen
  } = useApp();

  const [transferMode, setTransferMode] = useState<'manual' | 'auto'>('manual');
  const [selectedSuccessor, setSelectedSuccessor] = useState('Lê Minh Tuấn (Phó nhóm 🛡️)');

  if (!showTransferKeyModal) return null;

  const handleConfirmTransfer = () => {
    setUserRole('member');
    setShowTransferKeyModal(false);
    showToast(language === 'vi' 
      ? `Đã chuyển giao Key Trưởng nhóm cho ${selectedSuccessor} thành công!` 
      : `Group Owner Key successfully transferred to ${selectedSuccessor}!`);
    setCurrentScreen('chats');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 backdrop-blur-xs transition-opacity animate-in fade-in">
      <div 
        className="absolute inset-0" 
        onClick={() => setShowTransferKeyModal(false)} 
      />

      <div className="relative w-full max-w-md bg-white rounded-t-3xl max-h-[92vh] overflow-y-auto shadow-2xl z-10 space-y-4 pb-8 border-t border-slate-100 animate-in slide-in-from-bottom duration-300">
        {/* Drag handle */}
        <div className="w-12 h-1.5 bg-slate-300 rounded-full mx-auto mt-3" />

        {/* Group Info Summary Header */}
        <div className="px-5 pt-1 text-center space-y-3">
          <div className="relative inline-block">
            <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-sky-500 to-indigo-600 p-0.5 mx-auto">
              <img
                src="https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=200&q=80"
                alt="KINI Core"
                className="w-full h-full rounded-full object-cover border-2 border-white"
                referrerPolicy="no-referrer"
              />
            </div>
            <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-sky-600 text-white flex items-center justify-center border-2 border-white shadow-xs">
              <Edit2 className="w-3 h-3" />
            </div>
          </div>

          <div>
            <h3 className="text-base font-bold text-slate-900 flex items-center justify-center gap-1.5">
              <span>KINI Core Engineering</span>
              <Edit2 className="w-3.5 h-3.5 text-slate-400 cursor-pointer" />
            </h3>
            <p className="text-xs text-slate-500 font-medium">
              18 {language === 'vi' ? 'thành viên' : 'members'} • 2/10 {language === 'vi' ? 'Phó nhóm (Key phụ)' : 'Deputy Admins'}
            </p>
          </div>

          {/* 4 Quick Actions */}
          <div className="grid grid-cols-4 gap-2 pt-1">
            <button 
              onClick={() => showToast('Mời thành viên mới')}
              className="flex flex-col items-center gap-1 p-2 bg-slate-50 hover:bg-slate-100 rounded-xl transition-colors"
            >
              <UserPlus className="w-4 h-4 text-sky-600" />
              <span className="text-[11px] font-medium text-slate-700">{language === 'vi' ? 'Thêm' : 'Add'}</span>
            </button>
            <button 
              onClick={() => showToast('Tìm kiếm nội dung trong nhóm')}
              className="flex flex-col items-center gap-1 p-2 bg-slate-50 hover:bg-slate-100 rounded-xl transition-colors"
            >
              <Search className="w-4 h-4 text-sky-600" />
              <span className="text-[11px] font-medium text-slate-700">{language === 'vi' ? 'Tìm kiếm' : 'Search'}</span>
            </button>
            <button 
              onClick={() => showToast('Đổi hình nền nhóm')}
              className="flex flex-col items-center gap-1 p-2 bg-slate-50 hover:bg-slate-100 rounded-xl transition-colors"
            >
              <Palette className="w-4 h-4 text-sky-600" />
              <span className="text-[11px] font-medium text-slate-700">{language === 'vi' ? 'Hình nền' : 'Theme'}</span>
            </button>
            <button 
              onClick={() => showToast('Tắt chuông thông báo')}
              className="flex flex-col items-center gap-1 p-2 bg-slate-50 hover:bg-slate-100 rounded-xl transition-colors"
            >
              <BellOff className="w-4 h-4 text-sky-600" />
              <span className="text-[11px] font-medium text-slate-700">{language === 'vi' ? 'Tắt chuông' : 'Mute'}</span>
            </button>
          </div>
        </div>

        {/* Group Admin Permissions (Key) Section */}
        <div className="px-5 space-y-3">
          <div className="flex items-center gap-1.5 text-xs font-bold text-sky-800">
            <Shield className="w-4 h-4 text-sky-600" />
            <span>{language === 'vi' ? 'Quyền Quản Trị Viên (Key)' : 'Admin Permissions (Key)'}</span>
          </div>

          <div className="bg-slate-50/90 rounded-2xl p-3.5 border border-slate-100 space-y-3">
            {/* Toggle 1: Only Admin Chat */}
            <div className="flex items-center justify-between">
              <div className="pr-3">
                <h4 className="text-xs font-semibold text-slate-900">
                  {language === 'vi' ? 'Chỉ Trưởng/Phó nhóm gửi tin' : 'Only Admins can send messages'}
                </h4>
                <p className="text-[11px] text-slate-500 leading-tight">
                  {language === 'vi' ? 'Ngăn chặn spam và giữ trật tự thảo luận chung' : 'Prevent spam and maintain structured discussions'}
                </p>
              </div>
              <button
                onClick={() => updateGroupSettings('onlyAdminChat', !groupSettings.onlyAdminChat)}
                className={`w-11 h-6 rounded-full transition-colors relative p-0.5 shrink-0 ${
                  groupSettings.onlyAdminChat ? 'bg-sky-700' : 'bg-slate-300'
                }`}
              >
                <div className={`w-5 h-5 rounded-full bg-white shadow-xs transform transition-transform ${
                  groupSettings.onlyAdminChat ? 'translate-x-5' : 'translate-x-0'
                }`} />
              </button>
            </div>

            {/* Toggle 2: Only Admin Add */}
            <div className="flex items-center justify-between pt-2 border-t border-slate-200/60">
              <div className="pr-3">
                <h4 className="text-xs font-semibold text-slate-900">
                  {language === 'vi' ? 'Chỉ Trưởng/Phó nhóm thêm bạn' : 'Only Admins can add members'}
                </h4>
                <p className="text-[11px] text-slate-500 leading-tight">
                  {language === 'vi' ? 'Bảo vệ quyền riêng tư và danh sách thành viên nội bộ' : 'Protect privacy and internal roster'}
                </p>
              </div>
              <button
                onClick={() => updateGroupSettings('onlyAdminAdd', !groupSettings.onlyAdminAdd)}
                className={`w-11 h-6 rounded-full transition-colors relative p-0.5 shrink-0 ${
                  groupSettings.onlyAdminAdd ? 'bg-sky-700' : 'bg-slate-300'
                }`}
              >
                <div className={`w-5 h-5 rounded-full bg-white shadow-xs transform transition-transform ${
                  groupSettings.onlyAdminAdd ? 'translate-x-5' : 'translate-x-0'
                }`} />
              </button>
            </div>

            {/* Toggle 3: Approve new members */}
            <div className="flex items-center justify-between pt-2 border-t border-slate-200/60">
              <div className="pr-3">
                <h4 className="text-xs font-semibold text-slate-900">
                  {language === 'vi' ? 'Duyệt thành viên mới tham gia' : 'Require approval for new members'}
                </h4>
                <p className="text-[11px] text-slate-500 leading-tight">
                  {language === 'vi' ? 'Yêu cầu người phê duyệt xác nhận qua liên kết' : 'Require admin confirmation via invite link'}
                </p>
              </div>
              <button
                onClick={() => updateGroupSettings('approveNewMembers', !groupSettings.approveNewMembers)}
                className={`w-11 h-6 rounded-full transition-colors relative p-0.5 shrink-0 ${
                  groupSettings.approveNewMembers ? 'bg-sky-700' : 'bg-slate-300'
                }`}
              >
                <div className={`w-5 h-5 rounded-full bg-white shadow-xs transform transition-transform ${
                  groupSettings.approveNewMembers ? 'translate-x-5' : 'translate-x-0'
                }`} />
              </button>
            </div>
          </div>
        </div>

        {/* Transfer Key Modal Inner Card */}
        <div className="px-5 space-y-3.5 pt-2 border-t border-slate-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0 border border-rose-100">
              <RefreshCw className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-slate-900 leading-tight">
                {language === 'vi'
                  ? 'Xác Nhận Rời Nhóm & Bàn Giao Key Trưởng Nhóm'
                  : 'Confirm Leaving Group & Transfer Owner Key'}
              </h4>
              <p className="text-[11px] text-slate-600 mt-1 leading-normal">
                {language === 'vi' ? (
                  <>
                    Bạn là <strong className="text-amber-700">Trưởng nhóm (Key chính)</strong>. Khi rời nhóm, bạn bắt buộc phải chỉ định hoặc chuyển giao quyền Trưởng nhóm:
                  </>
                ) : (
                  <>
                    You are the <strong className="text-amber-700">Group Owner (Key chính)</strong>. You must delegate your ownership key prior to leaving:
                  </>
                )}
              </p>
            </div>
          </div>

          {/* Option 1: Manual successor selection */}
          <div 
            onClick={() => setTransferMode('manual')}
            className={`p-3.5 rounded-2xl border transition-all cursor-pointer ${
              transferMode === 'manual'
                ? 'bg-sky-50/70 border-sky-300 shadow-xs ring-1 ring-sky-300/40'
                : 'bg-white border-slate-200 hover:bg-slate-50'
            }`}
          >
            <div className="flex items-start gap-2.5">
              <input
                type="radio"
                checked={transferMode === 'manual'}
                onChange={() => setTransferMode('manual')}
                className="mt-0.5 text-sky-600 focus:ring-sky-500"
              />
              <div className="flex-1">
                <span className="text-xs font-bold text-slate-900 block">
                  {language === 'vi' ? 'Tự chọn thành viên kế nhiệm Key Trưởng nhóm' : 'Manually choose successor for Owner Key'}
                </span>
                <p className="text-[11px] text-slate-500 mt-0.5 leading-tight">
                  {language === 'vi'
                    ? 'Chuyển giao quyền hạn cao nhất trực tiếp cho một phó nhóm hoặc thành viên tin cậy.'
                    : 'Delegate highest channel authority directly to a trusted deputy or member.'}
                </p>

                {/* Dropdown selector */}
                <div className="mt-2.5 relative">
                  <select
                    value={selectedSuccessor}
                    onChange={(e) => setSelectedSuccessor(e.target.value)}
                    className="w-full py-2 px-3 bg-white border border-sky-200 rounded-xl text-xs font-semibold text-slate-800 appearance-none pr-8 focus:ring-2 focus:ring-sky-500/20 outline-hidden"
                  >
                    <option>Lê Minh Tuấn (Phó nhóm 🛡️)</option>
                    <option>Linh Trần (Phó nhóm 🛡️)</option>
                    <option>Nguyễn Thu Hà (UI/UX)</option>
                    <option>Capybara Chill</option>
                  </select>
                  <ChevronDown className="w-4 h-4 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                </div>
              </div>
            </div>
          </div>

          {/* Option 2: Automatic handover */}
          <div 
            onClick={() => setTransferMode('auto')}
            className={`p-3.5 rounded-2xl border transition-all cursor-pointer ${
              transferMode === 'auto'
                ? 'bg-sky-50/70 border-sky-300 shadow-xs ring-1 ring-sky-300/40'
                : 'bg-white border-slate-200 hover:bg-slate-50'
            }`}
          >
            <div className="flex items-start gap-2.5">
              <input
                type="radio"
                checked={transferMode === 'auto'}
                onChange={() => setTransferMode('auto')}
                className="mt-0.5 text-sky-600 focus:ring-sky-500"
              />
              <div className="flex-1">
                <span className="text-xs font-bold text-slate-900 block">
                  {language === 'vi' ? 'Hệ thống tự động chuyển giao' : 'Automatic system handover'}
                </span>
                <p className="text-[11px] text-slate-500 mt-0.5 leading-tight">
                  {language === 'vi'
                    ? 'KINI CHAT sẽ tự động trao Key chính cho Phó nhóm có thời gian hoạt động dài nhất hoặc thành viên tích cực nhất.'
                    : 'KINI CHAT automatically awards the Owner Key to the most active Deputy Admin.'}
                </p>
              </div>
            </div>
          </div>

          {/* Irreversible warning banner */}
          <div className="p-3 bg-amber-50/90 rounded-2xl border border-amber-200/80 flex items-start gap-2.5 text-amber-900 text-[11px] leading-relaxed">
            <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
            <p>
              {language === 'vi'
                ? 'Hành động này không thể hoàn tác sau khi bạn bấm xác nhận. Tất cả quyền sở hữu kênh sẽ thuộc về thành viên kế nhiệm.'
                : 'This action cannot be undone. All channel ownership rights will irrevocably transfer to the successor.'}
            </p>
          </div>

          {/* Confirmation buttons */}
          <div className="flex items-center gap-2.5 pt-2">
            <button
              onClick={() => setShowTransferKeyModal(false)}
              className="flex-1 py-2.5 px-4 bg-sky-50 hover:bg-sky-100 text-sky-700 text-xs font-bold rounded-xl transition-colors"
            >
              {language === 'vi' ? 'Hủy bỏ' : 'Cancel'}
            </button>

            <button
              onClick={handleConfirmTransfer}
              className="flex-1 py-2.5 px-4 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-xl shadow-md shadow-rose-600/20 transition-colors"
            >
              {language === 'vi' ? 'Xác nhận Chuyển & Rời...' : 'Confirm Transfer & Exit'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
