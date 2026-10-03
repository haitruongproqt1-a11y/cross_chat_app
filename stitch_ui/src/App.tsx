/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { HeaderBar } from './components/HeaderBar';
import { BottomNavBar } from './components/BottomNavBar';
import { ChatListScreen } from './components/ChatListScreen';
import { GroupChatScreen } from './components/GroupChatScreen';
import { RadarScreen } from './components/RadarScreen';
import { DiaryScreen } from './components/DiaryScreen';
import { SettingsScreen } from './components/SettingsScreen';
import { ContactsScreen } from './components/ContactsScreen';
import { VideoCallScreen } from './components/VideoCallScreen';
import { LoginScreen } from './components/LoginScreen';
import { ChatBottomSheet } from './components/ChatBottomSheet';
import { TransferKeyModal } from './components/TransferKeyModal';
import { QuickScreenSwitcher } from './components/QuickScreenSwitcher';

function MainAppShell() {
  const { currentScreen, toastMessage } = useApp();

  const isFullscreenView = currentScreen === 'call' || currentScreen === 'login';
  const showBottomNav = ['chats', 'contacts', 'radar', 'diary', 'settings'].includes(currentScreen);
  const showHeader = ['chats', 'radar', 'diary', 'settings', 'contacts'].includes(currentScreen);

  const getHeaderTitle = () => {
    switch (currentScreen) {
      case 'radar':
        return 'KINI CHAT Radar';
      case 'diary':
        return 'KINI CHAT Nhật Ký';
      case 'settings':
        return 'KINI CHAT Cài Đặt';
      case 'contacts':
        return 'KINI CHAT Danh Bạ';
      default:
        return 'KINI CHAT';
    }
  };

  return (
    <div className="min-h-screen bg-slate-900/5 flex items-center justify-center p-0 sm:p-4 md:p-6 antialiased font-sans">
      {/* Device Frame Wrapper for Responsive Mobile / Tablet / Desktop Presentation */}
      <main className="w-full max-w-md min-h-screen sm:min-h-[844px] sm:max-h-[920px] bg-[#F8FAFC] sm:rounded-[40px] shadow-2xl overflow-hidden flex flex-col relative sm:border-[8px] sm:border-slate-800">
        
        {/* Floating Quick Screen Switcher to immediately test all uploaded mockup screens */}
        <QuickScreenSwitcher />

        {/* Global Toast Notification */}
        {toastMessage && (
          <div className="fixed top-14 left-1/2 -translate-x-1/2 z-50 px-4 py-2 bg-slate-900/90 backdrop-blur-md text-white text-xs font-semibold rounded-full shadow-xl border border-white/10 animate-in fade-in slide-in-from-top-2 duration-200 pointer-events-none">
            {toastMessage}
          </div>
        )}

        {/* App Header Bar */}
        {showHeader && <HeaderBar title={getHeaderTitle()} />}

        {/* Main Screen Router */}
        <div className="flex-1 overflow-y-auto relative no-scrollbar">
          {currentScreen === 'login' && <LoginScreen />}
          {currentScreen === 'call' && <VideoCallScreen />}
          {currentScreen === 'chats' && <ChatListScreen />}
          {currentScreen === 'chat_detail' && <GroupChatScreen />}
          {currentScreen === 'radar' && <RadarScreen />}
          {currentScreen === 'diary' && <DiaryScreen />}
          {currentScreen === 'settings' && <SettingsScreen />}
          {currentScreen === 'contacts' && <ContactsScreen />}
        </div>

        {/* Bottom Navigation */}
        {showBottomNav && <BottomNavBar />}

        {/* Overlays / Modals */}
        <ChatBottomSheet />
        <TransferKeyModal />
      </main>
    </div>
  );
}

export default function App() {
  return (
    <AppProvider>
      <MainAppShell />
    </AppProvider>
  );
}
