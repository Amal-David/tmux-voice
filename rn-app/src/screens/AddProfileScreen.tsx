import React, {useMemo, useState} from 'react';
import {Alert, Pressable, StyleSheet, Text, TextInput, View} from 'react-native';
import {NativeStackScreenProps} from '@react-navigation/native-stack';
import {RootStackParamList} from '../navigation/AppNavigator';
import {useProfilesStore} from '../state/useProfilesStore';
import {palette, spacing, typography} from '../theme/theme';

const AddProfileScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, 'AddProfile'>
> = ({route, navigation}) => {
  const profile = useProfilesStore(state =>
    state.profiles.find(p => p.id === route.params?.profileId),
  );
  const {addProfile, updateProfile} = useProfilesStore();

  const [host, setHost] = useState(profile?.host ?? '');
  const [port, setPort] = useState(String(profile?.port ?? 22));
  const [username, setUsername] = useState(profile?.auth.username ?? '');
  const [password, setPassword] = useState(
    profile?.auth.type === 'password' ? profile.auth.password : '',
  );
  const [tmuxAttach, setTmuxAttach] = useState(profile?.tmuxAttach ?? 'tmux attach || tmux new');

  const isEditing = useMemo(() => Boolean(profile), [profile]);

  const onSave = async () => {
    if (!host || !username) {
      Alert.alert('Missing fields', 'Host and username are required');
      return;
    }

    const payload = {
      host,
      port: Number(port) || 22,
      auth: {type: 'password' as const, username, password},
      tmuxAttach,
    };

    if (isEditing && profile) {
      await updateProfile({...profile, ...payload});
    } else {
      await addProfile(payload);
    }

    navigation.goBack();
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{isEditing ? 'Edit profile' : 'New profile'}</Text>
      <TextInput
        value={host}
        onChangeText={setHost}
        placeholder="Host"
        style={styles.input}
        placeholderTextColor={palette.muted}
      />
      <TextInput
        value={port}
        onChangeText={setPort}
        placeholder="Port"
        keyboardType="numeric"
        style={styles.input}
        placeholderTextColor={palette.muted}
      />
      <TextInput
        value={username}
        onChangeText={setUsername}
        placeholder="Username"
        style={styles.input}
        placeholderTextColor={palette.muted}
      />
      <TextInput
        value={password}
        onChangeText={setPassword}
        placeholder="Password"
        secureTextEntry
        style={styles.input}
        placeholderTextColor={palette.muted}
      />
      <TextInput
        value={tmuxAttach}
        onChangeText={setTmuxAttach}
        placeholder="Tmux attach command"
        style={styles.input}
        placeholderTextColor={palette.muted}
      />

      <Pressable style={styles.button} onPress={onSave}>
        <Text style={styles.buttonText}>Save</Text>
      </Pressable>
    </View>
  );
};

export default AddProfileScreen;

const styles = StyleSheet.create({
  container: {flex: 1, backgroundColor: palette.background, padding: spacing(2)},
  title: {color: palette.text, fontSize: 22, marginBottom: spacing(2)},
  input: {
    backgroundColor: palette.surface,
    color: palette.text,
    padding: spacing(2),
    borderRadius: 10,
    marginBottom: spacing(1),
    fontFamily: typography.body,
  },
  button: {
    backgroundColor: palette.primary,
    padding: spacing(2),
    borderRadius: 10,
    alignItems: 'center',
    marginTop: spacing(2),
  },
  buttonText: {color: '#0b1220', fontWeight: '700'},
});
