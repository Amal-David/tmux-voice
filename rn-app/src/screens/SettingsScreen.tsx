import React from 'react';
import {StyleSheet, Text, View} from 'react-native';
import {palette, spacing, typography} from '../theme/theme';
import {appConfig} from '../services/config/config';

const SettingsScreen = () => (
  <View style={styles.container}>
    <Text style={styles.title}>Settings</Text>
    <Text style={styles.label}>Groq API key: {appConfig.groqApiKey ? 'set' : 'not set'}</Text>
    <Text style={styles.label}>
      Gemini API key: {appConfig.geminiApiKey ? 'set' : 'not set'}
    </Text>
    <Text style={styles.label}>
      Monitoring endpoint: {appConfig.monitoringEndpoint || 'not configured'}
    </Text>
  </View>
);

export default SettingsScreen;

const styles = StyleSheet.create({
  container: {flex: 1, backgroundColor: palette.background, padding: spacing(2)},
  title: {color: palette.text, fontSize: 22, marginBottom: spacing(2)},
  label: {color: palette.muted, marginBottom: spacing(1), fontFamily: typography.body},
});
