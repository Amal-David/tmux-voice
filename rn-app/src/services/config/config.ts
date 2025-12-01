import Config from 'react-native-config';

export const appConfig = {
  groqApiKey: Config.GROQ_API_KEY ?? '',
  geminiApiKey: Config.GEMINI_API_KEY ?? '',
  monitoringEndpoint: Config.MONITORING_ENDPOINT ?? '',
};
