import React from 'react';
import {StatusBar, View} from 'react-native';
import AppNavigator from './navigation/AppNavigator';
import {palette} from './theme/theme';

const App = () => (
  <View style={{flex: 1, backgroundColor: palette.background}}>
    <StatusBar barStyle="light-content" />
    <AppNavigator />
  </View>
);

export default App;
