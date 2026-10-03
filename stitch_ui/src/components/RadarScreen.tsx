import React, { useState } from 'react';
import { Navigation, Users, RefreshCw, MessageSquare, UserPlus, User, Shield, Check } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { NEARBY_USERS } from '../data/mockData';

export const RadarScreen: React.FC = () => {
  const { 
    gpsPrivacy, 
    setGpsPrivacy, 
    setCurrentScreen, 
    setActiveChatId, 
    language,
    showToast 
  } = useApp();

  const [activeFilter, setActiveFilter] = useState<'all' | 'male' | 'female' | 'online'>('all');
  const [addedFriends, setAddedFriends] = useState<Record<string, boolean>>({});

  const handleAddFriend = (id: string, name: string) => {
    setAddedFriends(prev => ({ ...prev, [id]: true }));
    showToast(language === 'vi' ? `Đã gửi lời mời kết bạn tới ${name}` : `Friend request sent to ${name}`);
  };

  const handleMessage = (userId: string) => {
    setActiveChatId('kini_core');
    setCurrentScreen('chat_detail');
  };

  const filteredUsers = NEARBY_USERS.filter(u => {
    if (activeFilter === 'male') return u.gender === 'male';
    if (activeFilter === 'female') return u.gender === 'female';
    if (activeFilter === 'online') return u.isOnline;
    return true;
  });

  return (
    <div className="pb-24 max-w-md mx-auto min-h-screen bg-[#F8FAFC]">
      {/* Location Status Bar */}
      <div className="p-4 pb-2">
        <div className="flex items-center justify-between bg-white p-3 rounded-2xl border border-slate-200/80 shadow-xs">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-sky-50 flex items-center justify-center text-sky-600">
              <Navigation className="w-4 h-4 fill-sky-500/20 text-sky-600 rotate-45" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-slate-900 flex items-center gap-1.5">
                <span>Cầu Giấy, Hà Nội</span>
              </h2>
              <p className="text-[11px] text-slate-500">
                {language === 'vi' ? 'Định vị chính xác • Bán kính 5km' : 'Accurate GPS • Radius 5km'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-full text-xs font-semibold border border-emerald-200/60">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>42 online</span>
          </div>
        </div>
      </div>

      {/* Radar Graphic Area */}
      <div className="relative mx-4 my-2 h-64 rounded-3xl bg-gradient-to-b from-sky-50/80 to-blue-50/40 border border-sky-100 flex items-center justify-center overflow-hidden">
        {/* Radar Concentric Rings */}
        <div className="absolute w-56 h-56 rounded-full border border-sky-200/60 pointer-events-none"></div>
        <div className="absolute w-40 h-40 rounded-full border border-sky-200/80 pointer-events-none"></div>
        <div className="absolute w-24 h-24 rounded-full border border-sky-300 pointer-events-none"></div>
        <div className="absolute w-10 h-10 rounded-full bg-sky-100/70 border border-sky-400 pointer-events-none"></div>

        {/* Sweep Scanner Beam */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none overflow-hidden">
          <div className="w-56 h-56 rounded-full animate-radar relative">
            <div className="absolute top-0 right-0 w-28 h-28 bg-gradient-to-br from-sky-400/30 to-transparent rounded-tr-full"></div>
          </div>
        </div>

        {/* Center Me Blip */}
        <div className="relative z-10 w-11 h-11 rounded-full bg-sky-700 text-white flex items-center justify-center shadow-lg shadow-sky-600/30 ring-4 ring-sky-300/40 animate-pulse">
          <Navigation className="w-5 h-5 fill-current text-white -rotate-45" />
          <span className="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-emerald-500 border-2 border-white rounded-full"></span>
        </div>

        {/* User Blips on Radar */}
        {NEARBY_USERS.map((user) => (
          <div
            key={user.id}
            style={{ left: `${user.radarX}%`, top: `${user.radarY}%` }}
            className="absolute -translate-x-1/2 -translate-y-1/2 z-20 flex flex-col items-center cursor-pointer group"
            onClick={() => handleMessage(user.id)}
          >
            <div className="relative">
              <div className="w-9 h-9 rounded-full overflow-hidden border-2 border-white shadow-md ring-1 ring-sky-300 group-hover:scale-125 transition-transform bg-white">
                <img
                  src={user.avatar}
                  alt={user.name}
                  className="w-full h-full object-cover"
                  referrerPolicy="no-referrer"
                />
              </div>
              {user.isOnline && (
                <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border border-white rounded-full"></span>
              )}
            </div>

            <span className="mt-1 px-1.5 py-0.2 bg-sky-600 text-white text-[9px] font-bold rounded-full shadow-xs whitespace-nowrap">
              {user.distance}
            </span>
          </div>
        ))}

        {/* Floating Scan Status */}
        <div className="absolute bottom-3 left-1/2 -translate-x-1/2 z-20">
          <div className="px-3.5 py-1.5 bg-sky-100/90 text-sky-800 text-[11px] font-semibold rounded-full border border-sky-200 shadow-xs flex items-center gap-1.5 whitespace-nowrap">
            <RefreshCw className="w-3 h-3 animate-spin text-sky-600" />
            <span>{language === 'vi' ? 'Đang tự động quét lân cận...' : 'Auto-scanning nearby...'}</span>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 px-4 py-2 overflow-x-auto no-scrollbar">
        <button
          onClick={() => setActiveFilter('all')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap transition-all ${
            activeFilter === 'all'
              ? 'bg-sky-600 text-white font-medium shadow-xs'
              : 'bg-white text-slate-600 border border-slate-200'
          }`}
        >
          {language === 'vi' ? 'Tất cả (42)' : 'All (42)'}
        </button>

        <button
          onClick={() => setActiveFilter('male')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap transition-all ${
            activeFilter === 'male'
              ? 'bg-sky-600 text-white font-medium shadow-xs'
              : 'bg-white text-slate-600 border border-slate-200'
          }`}
        >
          Nam ♂
        </button>

        <button
          onClick={() => setActiveFilter('female')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap transition-all ${
            activeFilter === 'female'
              ? 'bg-sky-600 text-white font-medium shadow-xs'
              : 'bg-white text-slate-600 border border-slate-200'
          }`}
        >
          Nữ ♀
        </button>

        <button
          onClick={() => setActiveFilter('online')}
          className={`px-3 py-1 text-xs rounded-full whitespace-nowrap flex items-center gap-1.5 transition-all ${
            activeFilter === 'online'
              ? 'bg-sky-600 text-white font-medium shadow-xs'
              : 'bg-white text-slate-600 border border-slate-200'
          }`}
        >
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
          <span>{language === 'vi' ? 'Đang online' : 'Online'}</span>
        </button>
      </div>

      {/* List Header */}
      <div className="flex items-center justify-between px-4 pt-2 pb-1 text-xs">
        <h3 className="font-bold text-slate-900">
          {language === 'vi' ? 'Kết nối bạn bè lân cận' : 'Nearby Connections'}
        </h3>
        <span className="text-slate-400">
          {language === 'vi' ? 'Sắp xếp theo khoảng cách' : 'Sorted by distance'}
        </span>
      </div>

      {/* Nearby Users List */}
      <div className="p-4 pt-1 space-y-3">
        {filteredUsers.map((user) => {
          const isFriend = addedFriends[user.id];

          return (
            <div
              key={user.id}
              className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-xs space-y-3 hover:border-sky-300 transition-all"
            >
              <div className="flex items-start gap-3">
                <div className="relative shrink-0">
                  <img
                    src={user.avatar}
                    alt={user.name}
                    className="w-13 h-13 rounded-full object-cover border border-slate-200"
                    referrerPolicy="no-referrer"
                  />
                  {user.isOnline && (
                    <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-0.5">
                    <div className="flex items-center gap-1.5">
                      <h4 className="text-sm font-bold text-slate-900 truncate">
                        {user.name}
                      </h4>
                      <span className="text-xs text-slate-500 font-medium">
                        {user.age} {user.gender === 'male' ? '♂' : '♀'}
                      </span>
                    </div>

                    <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-sky-50 text-sky-700 font-semibold text-[11px] rounded-full border border-sky-100">
                      <span>{user.distance}</span>
                    </span>
                  </div>

                  <p className="text-[11px] text-emerald-600 font-medium flex items-center gap-1 mb-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                    <span>{user.activityStatus}</span>
                  </p>

                  <p className="text-xs text-slate-600 leading-relaxed line-clamp-2">
                    {user.bio}
                  </p>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2 pt-1 border-t border-slate-100">
                <button
                  onClick={() => handleMessage(user.id)}
                  className="flex-1 py-2 px-3 bg-sky-700 hover:bg-sky-800 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                >
                  <MessageSquare className="w-3.5 h-3.5" />
                  <span>{language === 'vi' ? 'Nhắn tin' : 'Message'}</span>
                </button>

                <button
                  onClick={() => handleAddFriend(user.id, user.name)}
                  className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-colors border ${
                    isFriend
                      ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      : 'bg-sky-50 hover:bg-sky-100 text-sky-700 border-sky-200/60'
                  }`}
                >
                  {isFriend ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-emerald-600" />
                      <span>{language === 'vi' ? 'Đã gửi' : 'Requested'}</span>
                    </>
                  ) : (
                    <>
                      <UserPlus className="w-3.5 h-3.5" />
                      <span>{language === 'vi' ? 'Kết bạn' : 'Add Friend'}</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* GPS Privacy Setting Box */}
      <div className="px-4 pb-4">
        <div className="bg-sky-50/80 rounded-2xl p-4 border border-sky-100 space-y-3">
          <div className="flex items-center gap-2 text-sky-800 font-bold text-xs">
            <Shield className="w-4 h-4 text-sky-600" />
            <span>{language === 'vi' ? 'Cài đặt riêng tư định vị GPS' : 'GPS Location Privacy Settings'}</span>
          </div>

          <div className="flex items-center justify-between">
            <div className="pr-4">
              <h5 className="text-xs font-semibold text-slate-900">
                {language === 'vi' ? 'Cho phép người khác tìm thấy tôi quanh đây' : 'Allow others to find me nearby'}
              </h5>
              <p className="text-[11px] text-slate-500 leading-tight mt-0.5">
                {language === 'vi'
                  ? 'Hiển thị bạn trên màn hình radar của người dùng gần kề'
                  : 'Show you on radar screens of nearby users'}
              </p>
            </div>

            {/* Toggle switch */}
            <button
              onClick={() => setGpsPrivacy(prev => ({ ...prev, enabled: !prev.enabled }))}
              className={`w-11 h-6 rounded-full transition-colors relative p-0.5 shrink-0 ${
                gpsPrivacy.enabled ? 'bg-sky-700' : 'bg-slate-300'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white shadow-xs transform transition-transform ${
                  gpsPrivacy.enabled ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          <div className="pt-2 border-t border-sky-100 flex items-center justify-between">
            <label className="text-xs text-slate-700 flex items-center gap-2 cursor-pointer select-none">
              <Users className="w-3.5 h-3.5 text-slate-500" />
              <span>
                {language === 'vi'
                  ? 'Chỉ hiển thị với bạn bè hoặc thành viên cùng nhóm'
                  : 'Only show to friends or mutual group members'}
              </span>
            </label>

            <input
              type="checkbox"
              checked={gpsPrivacy.friendsOnly}
              onChange={(e) => setGpsPrivacy(prev => ({ ...prev, friendsOnly: e.target.checked }))}
              className="w-4 h-4 rounded text-sky-600 focus:ring-sky-500 border-slate-300 cursor-pointer"
            />
          </div>
        </div>
      </div>
    </div>
  );
};
