import React, { useState } from 'react';
import { Search, UserPlus, Users, Phone, Video, MessageSquare, Shield, Check } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { INITIAL_CHATS, NEARBY_USERS } from '../data/mockData';

export const ContactsScreen: React.FC = () => {
  const { setCurrentScreen, setActiveChatId, startCall, language, showToast } = useApp();
  const [search, setSearch] = useState('');

  const contacts = [
    { id: 'c1', name: 'Đặng Quang Huy', role: 'Thành viên', phone: '0912***456', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80', isOnline: true },
    { id: 'c2', name: 'Lê Minh Tuấn', role: 'Phó nhóm 🛡️', phone: '0983***789', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80', isOnline: true },
    { id: 'c3', name: 'Linh Trần', role: 'Phó nhóm 🛡️', phone: '0977***221', avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=200&q=80', isOnline: false },
    { id: 'c4', name: 'Nguyễn Mai Anh', role: 'Designer', phone: '0934***990', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80', isOnline: true },
    { id: 'c5', name: 'Nguyễn Thu Hà', role: 'Thiết kế UI/UX', phone: '0904***112', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80', isOnline: true },
  ].filter(c => c.name.toLowerCase().includes(search.toLowerCase()));

  return (
    <div className="pb-24 max-w-md mx-auto min-h-screen bg-[#F8FAFC]">
      {/* Search Bar */}
      <div className="p-4 pb-2">
        <div className="relative flex items-center">
          <Search className="absolute left-3.5 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={language === 'vi' ? 'Tìm kiếm danh bạ hoặc số điện thoại...' : 'Search contacts or phone numbers...'}
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-100 rounded-xl border border-slate-200 outline-hidden focus:bg-white focus:ring-2 focus:ring-sky-500/20"
          />
        </div>
      </div>

      {/* Quick shortcuts */}
      <div className="px-4 py-2 space-y-2">
        <button 
          onClick={() => showToast('Mở màn hình quét mã QR kết bạn')}
          className="w-full flex items-center gap-3 p-3 bg-white hover:bg-slate-50 rounded-2xl border border-slate-200 shadow-xs transition-colors"
        >
          <div className="w-10 h-10 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center">
            <UserPlus className="w-5 h-5" />
          </div>
          <div className="text-left">
            <h4 className="text-xs font-bold text-slate-900">{language === 'vi' ? 'Thêm bạn mới' : 'Add New Friend'}</h4>
            <p className="text-[11px] text-slate-500">{language === 'vi' ? 'Qua số điện thoại, QR code hoặc Radar' : 'Via phone, QR or nearby radar'}</p>
          </div>
        </button>

        <button 
          onClick={() => {
            setActiveChatId('kini_core');
            setCurrentScreen('chat_detail');
          }}
          className="w-full flex items-center gap-3 p-3 bg-white hover:bg-slate-50 rounded-2xl border border-slate-200 shadow-xs transition-colors"
        >
          <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
            <Users className="w-5 h-5" />
          </div>
          <div className="text-left">
            <h4 className="text-xs font-bold text-slate-900">{language === 'vi' ? 'Danh sách nhóm KINI CHAT' : 'KINI Groups & Channels'}</h4>
            <p className="text-[11px] text-slate-500">{language === 'vi' ? 'KINI Core Engineering (Trưởng nhóm)' : 'Managed channels with admin keys'}</p>
          </div>
        </button>
      </div>

      {/* Contacts List */}
      <div className="p-4 pt-2 space-y-2">
        <div className="text-xs font-bold text-slate-500 uppercase tracking-wider px-1">
          {language === 'vi' ? `Bạn bè (${contacts.length})` : `Friends (${contacts.length})`}
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 divide-y divide-slate-100 overflow-hidden shadow-xs">
          {contacts.map((c) => (
            <div key={c.id} className="p-3 flex items-center justify-between hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-3">
                <div className="relative">
                  <img
                    src={c.avatar}
                    alt={c.name}
                    className="w-10 h-10 rounded-full object-cover border border-slate-200"
                    referrerPolicy="no-referrer"
                  />
                  {c.isOnline && (
                    <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border border-white rounded-full"></span>
                  )}
                </div>

                <div>
                  <h4 className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                    <span>{c.name}</span>
                    {c.role.includes('Phó nhóm') && (
                      <span className="text-[9px] bg-sky-50 text-sky-700 px-1.5 py-0.2 rounded-full font-semibold border border-sky-200">
                        {c.role}
                      </span>
                    )}
                  </h4>
                  <p className="text-[11px] text-slate-500">{c.phone}</p>
                </div>
              </div>

              <div className="flex items-center gap-1 text-slate-500">
                <button
                  onClick={() => {
                    setActiveChatId('kini_core');
                    setCurrentScreen('chat_detail');
                  }}
                  className="p-2 hover:text-sky-600 hover:bg-sky-50 rounded-lg transition-colors"
                >
                  <MessageSquare className="w-4 h-4" />
                </button>
                <button
                  onClick={() => startCall()}
                  className="p-2 hover:text-sky-600 hover:bg-sky-50 rounded-lg transition-colors"
                >
                  <Phone className="w-4 h-4" />
                </button>
                <button
                  onClick={() => startCall()}
                  className="p-2 hover:text-sky-600 hover:bg-sky-50 rounded-lg transition-colors"
                >
                  <Video className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
