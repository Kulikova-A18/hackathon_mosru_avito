import React, { useState, useEffect } from 'react';
import {
  Paper,
  Typography,
  Box,
  Grid,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  Cell,
} from 'recharts';

interface AnalyticsData {
  screenViews: { date: string; views: number }[];
  elementClicks: { element: string; clicks: number }[];
  userEngagement: { action: string; count: number }[];
  conversionRate: number;
  averageSessionTime: number;
}

const AnalyticsPanel: React.FC<{ screenId?: string }> = ({ screenId }) => {
  const [timeRange, setTimeRange] = useState<'24h' | '7d' | '30d'>('7d');
  const [data, setData] = useState<AnalyticsData | null>(null);

  useEffect(() => {
    // Mock data - в реальном приложении будет API вызов
    const mockData: AnalyticsData = {
      screenViews: [
        { date: '2024-01-01', views: 1234 },
        { date: '2024-01-02', views: 1567 },
        { date: '2024-01-03', views: 1890 },
        { date: '2024-01-04', views: 1423 },
        { date: '2024-01-05', views: 1678 },
      ],
      elementClicks: [
        { element: 'buy_button', clicks: 456 },
        { element: 'details_button', clicks: 234 },
        { element: 'wishlist_button', clicks: 123 },
        { element: 'share_button', clicks: 89 },
      ],
      userEngagement: [
        { action: 'Clicks', count: 902 },
        { action: 'Impressions', count: 4567 },
        { action: 'Conversions', count: 123 },
      ],
      conversionRate: 2.7,
      averageSessionTime: 3.2,
    };
    setData(mockData);
  }, [screenId, timeRange]);

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

  if (!data) {
    return <Typography>Loading analytics...</Typography>;
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h4" gutterBottom>
        Analytics Dashboard
      </Typography>

      {/* Time Range Selector */}
      <FormControl sx={{ minWidth: 120, mb: 3 }}>
        <InputLabel>Time Range</InputLabel>
        <Select
          value={timeRange}
          label="Time Range"
          onChange={(e) => setTimeRange(e.target.value as any)}
        >
          <MenuItem value="24h">24 Hours</MenuItem>
          <MenuItem value="7d">7 Days</MenuItem>
          <MenuItem value="30d">30 Days</MenuItem>
        </Select>
      </FormControl>

      {/* KPI Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Total Views
              </Typography>
              <Typography variant="h4" component="div">
                {data.screenViews.reduce((sum, day) => sum + day.views, 0).toLocaleString()}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Conversion Rate
              </Typography>
              <Typography variant="h4" component="div">
                {data.conversionRate}%
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Avg Session
              </Typography>
              <Typography variant="h4" component="div">
                {data.averageSessionTime}m
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Total Clicks
              </Typography>
              <Typography variant="h4" component="div">
                {data.elementClicks.reduce((sum, el) => sum + el.clicks, 0)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3}>
        {/* Screen Views Over Time */}
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Screen Views Over Time
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={data.screenViews}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="views" stroke="#8884d8" />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Element Clicks */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Element Clicks
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={data.elementClicks}
                  dataKey="clicks"
                  nameKey="element"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label
                >
                  {data.elementClicks.map((_entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* User Engagement */}
        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              User Engagement
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={data.userEngagement}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="action" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="count" fill="#82ca9d" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default AnalyticsPanel;