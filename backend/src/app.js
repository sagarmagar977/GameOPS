import cors from 'cors';
import express from 'express';
import healthRoutes from './routes/health.js';
import gameRoutes from './routes/games.js';
import credentialRoutes from './routes/credentials.js';
import cashoutRuleRoutes from './routes/cashoutRules.js';
import cashoutRoutes from './routes/cashouts.js';
import faqRoutes from './routes/faqs.js';
import discussionRoutes from './routes/discussions.js';
import taskRoutes from './routes/tasks.js';

export function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.use('/api/health', healthRoutes);
  app.use('/api/games', gameRoutes);
  app.use('/api/credentials', credentialRoutes);
  app.use('/api/cashout-rules', cashoutRuleRoutes);
  app.use('/api/cashouts', cashoutRoutes);
  app.use('/api/faqs', faqRoutes);
  app.use('/api/discussions', discussionRoutes);
  app.use('/api/tasks', taskRoutes);

  return app;
}
