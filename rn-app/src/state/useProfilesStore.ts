import AsyncStorage from '@react-native-async-storage/async-storage';
import {nanoid} from 'nanoid/non-secure';
import {create} from 'zustand';
import {SshProfile, SshSession} from '../types/ssh';

const PROFILE_KEY = 'tmuxVoice.profiles.v1';

interface ProfilesState {
  profiles: SshProfile[];
  sessions: SshSession[];
  recentProfileId?: string;
  hydrate: () => Promise<void>;
  addProfile: (profile: Omit<SshProfile, 'id'>) => Promise<SshProfile>;
  updateProfile: (profile: SshProfile) => Promise<void>;
  deleteProfile: (id: string) => Promise<void>;
  setRecentProfile: (id: string) => void;
  addSession: (session: SshSession) => void;
  removeSession: (id: string) => void;
}

const persistProfiles = async (profiles: SshProfile[]) => {
  await AsyncStorage.setItem(PROFILE_KEY, JSON.stringify(profiles));
};

export const useProfilesStore = create<ProfilesState>((set, get) => ({
  profiles: [],
  sessions: [],
  hydrate: async () => {
    const raw = await AsyncStorage.getItem(PROFILE_KEY);
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw) as SshProfile[];
      set({profiles: parsed});
    } catch (error) {
      console.warn('Failed to parse profiles', error);
    }
  },
  addProfile: async profile => {
    const next: SshProfile = {...profile, id: nanoid()};
    const profiles = [...get().profiles, next];
    set({profiles});
    await persistProfiles(profiles);
    return next;
  },
  updateProfile: async profile => {
    const profiles = get().profiles.map(item =>
      item.id === profile.id ? profile : item,
    );
    set({profiles});
    await persistProfiles(profiles);
  },
  deleteProfile: async id => {
    const profiles = get().profiles.filter(profile => profile.id !== id);
    set({profiles});
    await persistProfiles(profiles);
  },
  setRecentProfile: id => set({recentProfileId: id}),
  addSession: session => set(state => ({sessions: [...state.sessions, session]})),
  removeSession: id =>
    set(state => ({sessions: state.sessions.filter(item => item.id !== id)})),
}));
