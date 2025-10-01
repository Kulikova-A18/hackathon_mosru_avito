import axios from 'axios';

const API_BASE_URL = 'http://localhost:8080/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 5000,
});

export const healthCheck = async () => {
  const response = await api.get('/health');
  return response.data;
};

export const getScreens = async () => {
  const response = await api.get('/screens');
  return response.data;
};

export const getScreen = async (id: string) => {
  const response = await api.get(`/screens/${id}`);
  return response.data;
};

export const createScreen = async (screen: any) => {
  const response = await api.post('/screens', screen);
  return response.data;
};

export const updateScreen = async (id: string, screen: any) => {
  const response = await api.put(`/screens/${id}`, screen);
  return response.data;
};

export const getComponents = async () => {
  const response = await api.get('/components');
  return response.data;
};

export const trackEvent = async (event: any) => {
  await api.post('/analytics/events', event);
};
