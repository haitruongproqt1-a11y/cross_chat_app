import React, { createContext, useContext, useState, useEffect } from 'react';
import { ScreenType, ChatItem, ChatMessage, FeedPost, LanguageCode, UserRole } from '../types';
import { INITIAL_CHATS, GROUP_CHAT_MESSAGES, FEED_POSTS, CURRENT_USER } from '../data/mockData';

interface AppContextType {
  currentScreen: ScreenType;
  setCurrentScreen: (s: ScreenType) => void;
  activeChatId: string;
  setActiveChatId: (id: string) => void;
  language: LanguageCode;
  setLanguage: (l: LanguageCode) => void;
  activeSheetContact: ChatItem | null;
  setActiveSheetContact: (c: ChatItem | null) => void;
  showTransferKeyModal: boolean;
  setShowTransferKeyModal: (show: boolean) => void;
  chats: ChatItem[];
  pinChat: (id: string) => void;
  deleteChat: (id: string) => void;
  markAsRead: (id: string) => void;
  messages: ChatMessage[];
  addMessage: (text: string) => void;
  posts: FeedPost[];
  likePost: (id: string) => void;
  addComment: (postId: string, text: string) => void;
  createPost: (text: string) => void;
  userRole: UserRole;
  setUserRole: (role: UserRole) => void;
  groupSettings: {
    onlyAdminChat: boolean;
    onlyAdminAdd: boolean;
    approveNewMembers: boolean;
  };
  updateGroupSettings: (key: 'onlyAdminChat' | 'onlyAdminAdd' | 'approveNewMembers', val: boolean) => void;
  gpsPrivacy: {
    enabled: boolean;
    friendsOnly: boolean;
  };
  setGpsPrivacy: React.Dispatch<React.SetStateAction<{ enabled: boolean; friendsOnly: boolean }>>;
  selectedTheme: string;
  setSelectedTheme: (t: string) => void;
  isCallActive: boolean;
  startCall: () => void;
  endCall: () => void;
  callDuration: number;
  isCallMuted: boolean;
  toggleCallMute: () => void;
  isCallCamOff: boolean;
  toggleCallCam: () => void;
  isSharingScreen: boolean;
  toggleScreenShare: () => void;
  toastMessage: string | null;
  showToast: (msg: string) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentScreen, setCurrentScreen] = useState<ScreenType>('chats');
  const [activeChatId, setActiveChatId] = useState<string>('kini_core');
  const [language, setLanguage] = useState<LanguageCode>('vi');
  const [activeSheetContact, setActiveSheetContact] = useState<ChatItem | null>(null);
  const [showTransferKeyModal, setShowTransferKeyModal] = useState<boolean>(false);
  const [chats, setChats] = useState<ChatItem[]>(INITIAL_CHATS);
  const [messages, setMessages] = useState<ChatMessage[]>(GROUP_CHAT_MESSAGES);
  const [posts, setPosts] = useState<FeedPost[]>(FEED_POSTS);
  const [userRole, setUserRole] = useState<UserRole>('owner');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const [groupSettings, setGroupSettings] = useState({
    onlyAdminChat: true,
    onlyAdminAdd: true,
    approveNewMembers: false
  });

  const [gpsPrivacy, setGpsPrivacy] = useState({
    enabled: true,
    friendsOnly: false
  });

  const [selectedTheme, setSelectedTheme] = useState('capybara');

  // Call states
  const [isCallActive, setIsCallActive] = useState(false);
  const [callDuration, setCallDuration] = useState(926); // ~15:26
  const [isCallMuted, setIsCallMuted] = useState(false);
  const [isCallCamOff, setIsCallCamOff] = useState(false);
  const [isSharingScreen, setIsSharingScreen] = useState(true);

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (isCallActive) {
      timer = setInterval(() => {
        setCallDuration(d => d + 1);
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [isCallActive]);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage(null);
    }, 3000);
  };

  const startCall = () => {
    setIsCallActive(true);
    setCurrentScreen('call');
  };

  const endCall = () => {
    setIsCallActive(false);
    setCurrentScreen('chats');
    showToast(language === 'vi' ? 'Cuộc gọi đã kết thúc' : 'Call ended');
  };

  const toggleCallMute = () => setIsCallMuted(!isCallMuted);
  const toggleCallCam = () => setIsCallCamOff(!isCallCamOff);
  const toggleScreenShare = () => setIsSharingScreen(!isSharingScreen);

  const pinChat = (id: string) => {
    setChats(prev =>
      prev.map(c => (c.id === id ? { ...c, isPinned: !c.isPinned } : c))
    );
    showToast(language === 'vi' ? 'Đã cập nhật trạng thái ghim' : 'Pinned status updated');
  };

  const deleteChat = (id: string) => {
    setChats(prev => prev.filter(c => c.id !== id));
    setActiveSheetContact(null);
    showToast(language === 'vi' ? 'Đã xóa cuộc trò chuyện' : 'Conversation deleted');
  };

  const markAsRead = (id: string) => {
    setChats(prev =>
      prev.map(c => (c.id === id ? { ...c, unreadCount: 0 } : c))
    );
    setActiveSheetContact(null);
    showToast(language === 'vi' ? 'Đã đánh dấu đã đọc' : 'Marked as read');
  };

  const addMessage = (text: string) => {
    if (!text.trim()) return;
    const newMsg: ChatMessage = {
      id: `msg_${Date.now()}`,
      senderId: CURRENT_USER.id,
      senderName: CURRENT_USER.name,
      senderRole: userRole,
      roleTag: userRole === 'owner' ? 'Trưởng nhóm' : userRole === 'deputy' ? 'Phó nhóm' : undefined,
      avatar: CURRENT_USER.avatar,
      type: 'text',
      content: text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      status: 'sent'
    };
    setMessages(prev => [...prev, newMsg]);
  };

  const likePost = (id: string) => {
    setPosts(prev =>
      prev.map(post => {
        if (post.id === id) {
          const isLiked = !post.isLiked;
          return {
            ...post,
            isLiked,
            likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1
          };
        }
        return post;
      })
    );
  };

  const addComment = (postId: string, text: string) => {
    if (!text.trim()) return;
    setPosts(prev =>
      prev.map(post => {
        if (post.id === postId) {
          const newComment = {
            id: `c_${Date.now()}`,
            author: CURRENT_USER.name,
            avatar: CURRENT_USER.avatar,
            content: text,
            timeAgo: 'Vừa xong'
          };
          return {
            ...post,
            commentsCount: post.commentsCount + 1,
            comments: [...post.comments, newComment]
          };
        }
        return post;
      })
    );
    showToast(language === 'vi' ? 'Đã gửi bình luận' : 'Comment added');
  };

  const createPost = (text: string) => {
    if (!text.trim()) return;
    const newPost: FeedPost = {
      id: `post_${Date.now()}`,
      author: CURRENT_USER.name,
      authorRole: 'owner',
      roleTag: 'Key chính',
      avatar: CURRENT_USER.avatar,
      timeAgo: 'Vừa xong',
      privacy: 'friends',
      content: text,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      comments: []
    };
    setPosts(prev => [newPost, ...prev]);
    showToast(language === 'vi' ? 'Đã đăng bài viết mới' : 'Post published');
  };

  const updateGroupSettings = (
    key: 'onlyAdminChat' | 'onlyAdminAdd' | 'approveNewMembers',
    val: boolean
  ) => {
    setGroupSettings(prev => ({ ...prev, [key]: val }));
    showToast(language === 'vi' ? 'Đã cập nhật cấu hình nhóm' : 'Group settings updated');
  };

  return (
    <AppContext.Provider
      value={{
        currentScreen,
        setCurrentScreen,
        activeChatId,
        setActiveChatId,
        language,
        setLanguage,
        activeSheetContact,
        setActiveSheetContact,
        showTransferKeyModal,
        setShowTransferKeyModal,
        chats,
        pinChat,
        deleteChat,
        markAsRead,
        messages,
        addMessage,
        posts,
        likePost,
        addComment,
        createPost,
        userRole,
        setUserRole,
        groupSettings,
        updateGroupSettings,
        gpsPrivacy,
        setGpsPrivacy,
        selectedTheme,
        setSelectedTheme,
        isCallActive,
        startCall,
        endCall,
        callDuration,
        isCallMuted,
        toggleCallMute,
        isCallCamOff,
        toggleCallCam,
        isSharingScreen,
        toggleScreenShare,
        toastMessage,
        showToast
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
};
