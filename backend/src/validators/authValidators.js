import { z } from 'zod';

export const registerSchema = z
  .object({
    email: z.string().trim().email(),
    password: z.string().min(6),
    confirmPassword: z.string().min(6),
  })
  .refine((data) => data.password === data.confirmPassword, {
    path: ['confirmPassword'],
    message: 'Passwords do not match',
  });

export const loginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(1),
});
