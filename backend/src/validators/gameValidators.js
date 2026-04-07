import { z } from 'zod';

const optionalHttpUrl = z
  .string()
  .trim()
  .refine((value) => value === '' || /^https?:\/\/\S+$/i.test(value), {
    message: 'Enter a valid http:// or https:// URL',
  })
  .default('');

export const gameSchema = z.object({
  name: z.string().trim().min(1),
  slug: z.string().trim().min(1),
  website_url: optionalHttpUrl,
  is_active: z.boolean().default(true),
  is_highlighted: z.boolean().default(false),
  notes: z.string().trim().optional().or(z.literal('')).default(''),
});

export const credentialSchema = z.object({
  game_id: z.string().uuid(),
  username: z.string().min(1),
  password: z.string().min(1),
  label: z.string().optional().or(z.literal('')).default(''),
  is_primary: z.boolean().default(false),
  notes: z.string().optional().or(z.literal('')).default(''),
});

export const cashoutRuleSchema = z.object({
  game_id: z.string().uuid(),
  freeplay_label: z.string().optional().or(z.literal('')).default(''),
  payout_min: z.number().nonnegative(),
  payout_max: z.number().nonnegative(),
  slope_percent: z.number().min(0).max(100).default(0),
  is_freeplay_enabled: z.boolean().default(true),
  notes: z.string().optional().or(z.literal('')).default(''),
});

export const cashoutSchema = z.object({
  game_id: z.string().uuid(),
  credential_id: z.string().uuid().optional().nullable(),
  player_name: z.string().min(1),
  amount: z.number().positive(),
  status: z.enum(['pending', 'completed', 'ignored']).default('pending'),
  notes: z.string().optional().or(z.literal('')).default(''),
});

export const faqSchema = z.object({
  game_id: z.string().uuid().optional().nullable(),
  question: z.string().min(1),
  answer: z.string().min(1),
  tags: z.array(z.string()).default([]),
  approved: z.boolean().default(false),
});

export const discussionSchema = z.object({
  game_id: z.string().uuid().optional().nullable(),
  author_name: z.string().min(1),
  content: z.string().min(1),
  parent_id: z.string().uuid().optional().nullable(),
  approved: z.boolean().default(false),
});

export const taskSchema = z.object({
  game_id: z.string().uuid(),
  credential_id: z.string().uuid().optional().nullable(),
  action: z.enum(['login', 'fetch_balance', 'recharge', 'freeplay_check', 'cashout_preview']),
  username: z.string().min(1),
});
