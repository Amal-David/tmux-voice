import React, {useEffect, useMemo, useRef, useState} from 'react';
import {Alert, StyleSheet, Text, View} from 'react-native';
import {NativeStackScreenProps} from '@react-navigation/native-stack';
import {RootStackParamList} from '../navigation/AppNavigator';
import {useProfilesStore} from '../state/useProfilesStore';
import {SshService} from '../services/ssh/SshService';
import {Terminal} from 'xterm-headless';
import {TerminalView} from '../terminal/TerminalView';
import {palette, spacing, typography} from '../theme/theme';
import {TerminalSize} from '../types/ssh';
import {nanoid} from 'nanoid/non-secure';

const TerminalScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, 'Terminal'>
> = ({route, navigation}) => {
  const profile = useProfilesStore(state =>
    state.profiles.find(item => item.id === route.params.profileId),
  );
  const addSession = useProfilesStore(state => state.addSession);
  const removeSession = useProfilesStore(state => state.removeSession);

  const [status, setStatus] = useState('connecting');
  const [size] = useState<TerminalSize>({cols: 120, rows: 32});
  const terminal = useMemo(() => new Terminal({cols: 120, rows: 32}), []);
  const serviceRef = useRef(new SshService({logger: console.log}));

  useEffect(() => {
    if (!profile) {
      Alert.alert('Missing profile');
      navigation.goBack();
      return;
    }

    const service = serviceRef.current;
    const sessionId = nanoid();

    const listener = (event: any) => {
      if (event.type === 'connected') {
        setStatus('connected');
        addSession({id: sessionId, profile, connectedAt: Date.now()});
      }
      if (event.type === 'data') {
        terminal.write(event.payload);
      }
      if (event.type === 'closed') {
        setStatus('closed');
        removeSession(sessionId);
      }
    };

    service.on('terminal', listener);

    service
      .connect(profile, size)
      .catch(error => Alert.alert('SSH failed', error.message));

    return () => {
      service.off('terminal', listener);
      service.dispose();
      removeSession(sessionId);
    };
  }, [addSession, navigation, profile, removeSession, size, terminal]);

  return (
    <View style={styles.container}>
      <Text style={styles.header}>Terminal ({status})</Text>
      <TerminalView
        terminal={terminal}
        size={size}
        onInput={text => serviceRef.current.send(text)}
        onResize={next => serviceRef.current.resize(next)}
      />
    </View>
  );
};

export default TerminalScreen;

const styles = StyleSheet.create({
  container: {flex: 1, backgroundColor: palette.background},
  header: {
    color: palette.text,
    fontSize: 16,
    padding: spacing(2),
    fontFamily: typography.body,
  },
});
