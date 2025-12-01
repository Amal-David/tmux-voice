import React, {useEffect} from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import ConnectionsScreen from '../screens/ConnectionsScreen';
import TerminalScreen from '../screens/TerminalScreen';
import SettingsScreen from '../screens/SettingsScreen';
import AddProfileScreen from '../screens/AddProfileScreen';
import {useProfilesStore} from '../state/useProfilesStore';

export type RootStackParamList = {
  Connections: undefined;
  Terminal: {profileId: string};
  Settings: undefined;
  AddProfile: {profileId?: string};
};

const Stack = createNativeStackNavigator<RootStackParamList>();

const AppNavigator = () => {
  const hydrate = useProfilesStore(state => state.hydrate);

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Connections" component={ConnectionsScreen} />
        <Stack.Screen name="Terminal" component={TerminalScreen} />
        <Stack.Screen name="Settings" component={SettingsScreen} />
        <Stack.Screen name="AddProfile" component={AddProfileScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
