import React from 'react';
import {FlatList, Pressable, StyleSheet, Text, View} from 'react-native';
import {NativeStackScreenProps} from '@react-navigation/native-stack';
import {RootStackParamList} from '../navigation/AppNavigator';
import {useProfilesStore} from '../state/useProfilesStore';
import {palette, spacing, typography} from '../theme/theme';

const ConnectionsScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, 'Connections'>
> = ({navigation}) => {
  const {profiles, sessions} = useProfilesStore();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Connections</Text>
        <Pressable onPress={() => navigation.navigate('AddProfile', {})}>
          <Text style={styles.link}>Add Profile</Text>
        </Pressable>
      </View>

      <Text style={styles.section}>Profiles</Text>
      <FlatList
        data={profiles}
        keyExtractor={item => item.id}
        renderItem={({item}) => (
          <Pressable
            style={styles.card}
            onPress={() => navigation.navigate('Terminal', {profileId: item.id})}>
            <Text style={styles.cardTitle}>{item.host}</Text>
            <Text style={styles.cardSubtitle}>
              {item.description || item.auth.username}
            </Text>
          </Pressable>
        )}
      />

      <Text style={styles.section}>Active sessions</Text>
      <FlatList
        data={sessions}
        keyExtractor={item => item.id}
        renderItem={({item}) => (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>{item.profile.host}</Text>
            <Text style={styles.cardSubtitle}>
              Connected {new Date(item.connectedAt).toLocaleTimeString()}
            </Text>
          </View>
        )}
      />
    </View>
  );
};

export default ConnectionsScreen;

const styles = StyleSheet.create({
  container: {flex: 1, backgroundColor: palette.background, padding: spacing(2)},
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing(2),
  },
  title: {
    color: palette.text,
    fontSize: 24,
    fontFamily: typography.body,
  },
  link: {color: palette.primary, fontSize: 16},
  section: {
    marginTop: spacing(2),
    marginBottom: spacing(1),
    color: palette.muted,
    fontFamily: typography.body,
  },
  card: {
    padding: spacing(2),
    backgroundColor: palette.surface,
    borderRadius: 12,
    marginBottom: spacing(1),
  },
  cardTitle: {color: palette.text, fontSize: 16, fontFamily: typography.body},
  cardSubtitle: {color: palette.muted, marginTop: 4},
});
