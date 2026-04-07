export const openApiDocument = {
  openapi: '3.0.3',
  info: {
    title: 'GameOps Backend API',
    version: '1.0.0',
    description: 'Interactive API documentation for the GameOps backend.',
  },
  servers: [
    {
      url: '/',
      description: 'Current server',
    },
  ],
  tags: [
    { name: 'Auth' },
    { name: 'Health' },
    { name: 'Games' },
    { name: 'Credentials' },
    { name: 'Cashout Rules' },
    { name: 'Cashouts' },
    { name: 'FAQs' },
    { name: 'Discussions' },
    { name: 'Tasks' },
  ],
  paths: {
    '/api/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Create an operator account',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/RegisterInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created account and JWT token',
          },
        },
      },
    },
    '/api/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Log in with email and password',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/LoginInput',
              },
            },
          },
        },
        responses: {
          200: {
            description: 'JWT token and current user',
          },
        },
      },
    },
    '/api/auth/me': {
      get: {
        tags: ['Auth'],
        summary: 'Get the current authenticated user',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'Current user',
          },
        },
      },
    },
    '/api/auth/bootstrap-admin': {
      get: {
        tags: ['Auth'],
        summary: 'Show the seeded admin email',
        responses: {
          200: {
            description: 'Seeded admin account hint',
          },
        },
      },
    },
    '/api/health': {
      get: {
        tags: ['Health'],
        summary: 'Check service health',
        responses: {
          200: {
            description: 'Backend health payload',
          },
        },
      },
    },
    '/api/games': {
      get: {
        tags: ['Games'],
        summary: 'List games',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'A list of games',
          },
        },
      },
      post: {
        tags: ['Games'],
        summary: 'Create a game',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/GameInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created game',
          },
        },
      },
    },
    '/api/games/{id}': {
      put: {
        tags: ['Games'],
        summary: 'Update a game',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/GamePatch',
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Updated game',
          },
        },
      },
      delete: {
        tags: ['Games'],
        summary: 'Delete a game',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        responses: {
          200: {
            description: 'Deleted game id',
          },
        },
      },
    },
    '/api/credentials': {
      get: {
        tags: ['Credentials'],
        summary: 'List credentials',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'gameId',
            in: 'query',
            required: false,
            schema: { type: 'integer' },
          },
        ],
        responses: {
          200: {
            description: 'A list of credentials',
          },
        },
      },
      post: {
        tags: ['Credentials'],
        summary: 'Create a credential',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/CredentialInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created credential',
          },
        },
      },
    },
    '/api/credentials/{id}': {
      put: {
        tags: ['Credentials'],
        summary: 'Update a credential',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/CredentialPatch',
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Updated credential',
          },
        },
      },
      delete: {
        tags: ['Credentials'],
        summary: 'Delete a credential',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        responses: {
          200: {
            description: 'Deleted credential id',
          },
        },
      },
    },
    '/api/cashout-rules': {
      get: {
        tags: ['Cashout Rules'],
        summary: 'List cashout rules',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'A list of cashout rules',
          },
        },
      },
      post: {
        tags: ['Cashout Rules'],
        summary: 'Create or upsert a cashout rule',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/CashoutRuleInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created or updated cashout rule',
          },
        },
      },
    },
    '/api/cashout-rules/{id}': {
      put: {
        tags: ['Cashout Rules'],
        summary: 'Update a cashout rule',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/CashoutRulePatch',
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Updated cashout rule',
          },
        },
      },
    },
    '/api/cashouts': {
      get: {
        tags: ['Cashouts'],
        summary: 'List recent cashouts',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'A list of cashouts',
          },
        },
      },
      post: {
        tags: ['Cashouts'],
        summary: 'Create a cashout',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/CashoutInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created cashout',
          },
        },
      },
    },
    '/api/faqs': {
      get: {
        tags: ['FAQs'],
        summary: 'List or search FAQs',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'q',
            in: 'query',
            required: false,
            schema: { type: 'string' },
          },
        ],
        responses: {
          200: {
            description: 'A list of FAQs',
          },
        },
      },
      post: {
        tags: ['FAQs'],
        summary: 'Create an FAQ',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/FaqInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created FAQ',
          },
        },
      },
    },
    '/api/faqs/{id}': {
      put: {
        tags: ['FAQs'],
        summary: 'Update an FAQ',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/FaqPatch',
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Updated FAQ',
          },
        },
      },
      delete: {
        tags: ['FAQs'],
        summary: 'Delete an FAQ',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        responses: {
          200: {
            description: 'Deleted FAQ id',
          },
        },
      },
    },
    '/api/discussions': {
      get: {
        tags: ['Discussions'],
        summary: 'List or search discussions',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'q',
            in: 'query',
            required: false,
            schema: { type: 'string' },
          },
        ],
        responses: {
          200: {
            description: 'A list of discussions',
          },
        },
      },
      post: {
        tags: ['Discussions'],
        summary: 'Create a discussion',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/DiscussionInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created discussion',
          },
        },
      },
    },
    '/api/discussions/{id}': {
      put: {
        tags: ['Discussions'],
        summary: 'Update a discussion',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/DiscussionPatch',
              },
            },
          },
        },
        responses: {
          200: {
            description: 'Updated discussion',
          },
        },
      },
      delete: {
        tags: ['Discussions'],
        summary: 'Delete a discussion',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
        ],
        responses: {
          200: {
            description: 'Deleted discussion id',
          },
        },
      },
    },
    '/api/tasks': {
      post: {
        tags: ['Tasks'],
        summary: 'Queue an automation task',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/TaskInput',
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created task',
          },
        },
      },
    },
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
    schemas: {
      GameInput: {
        type: 'object',
        required: ['name', 'slug'],
        properties: {
          name: { type: 'string', example: 'PokerStars' },
          slug: { type: 'string', example: 'pokerstars' },
          website_url: { type: 'string', nullable: true, example: 'https://example.com' },
          is_active: { type: 'boolean', example: true },
          is_highlighted: { type: 'boolean', example: false },
          notes: { type: 'string', nullable: true, example: 'Priority game' },
        },
      },
      GamePatch: {
        allOf: [{ $ref: '#/components/schemas/GameInput' }],
      },
      CredentialInput: {
        type: 'object',
        required: ['game_id', 'username', 'password'],
        properties: {
          game_id: { type: 'integer', example: 1 },
          username: { type: 'string', example: 'player01' },
          password: { type: 'string', example: 'super-secret' },
          label: { type: 'string', nullable: true, example: 'Main login' },
          is_primary: { type: 'boolean', example: true },
          notes: { type: 'string', nullable: true, example: '2FA enabled' },
        },
      },
      CredentialPatch: {
        allOf: [{ $ref: '#/components/schemas/CredentialInput' }],
      },
      CashoutRuleInput: {
        type: 'object',
        required: ['game_id'],
        properties: {
          game_id: { type: 'integer', example: 1 },
          freeplay_label: { type: 'string', nullable: true, example: 'Bonus play' },
          payout_min: { type: 'number', nullable: true, example: 10 },
          payout_max: { type: 'number', nullable: true, example: 500 },
          slope_percent: { type: 'number', nullable: true, example: 15 },
          is_freeplay_enabled: { type: 'boolean', example: true },
          notes: { type: 'string', nullable: true, example: 'Weekend exceptions apply' },
        },
      },
      CashoutRulePatch: {
        allOf: [{ $ref: '#/components/schemas/CashoutRuleInput' }],
      },
      CashoutInput: {
        type: 'object',
        required: ['game_id', 'player_name', 'amount', 'status'],
        properties: {
          game_id: { type: 'integer', example: 1 },
          credential_id: { type: 'integer', nullable: true, example: 2 },
          player_name: { type: 'string', example: 'Alex' },
          amount: { type: 'number', example: 150.5 },
          status: { type: 'string', example: 'pending' },
          notes: { type: 'string', nullable: true, example: 'Requested via chat' },
        },
      },
      FaqInput: {
        type: 'object',
        required: ['question', 'answer'],
        properties: {
          game_id: { type: 'integer', nullable: true, example: 1 },
          question: { type: 'string', example: 'How do I reset my password?' },
          answer: { type: 'string', example: 'Open settings and choose reset password.' },
          tags: {
            type: 'array',
            items: { type: 'string' },
            example: ['login', 'account'],
          },
          approved: { type: 'boolean', example: true },
        },
      },
      FaqPatch: {
        allOf: [{ $ref: '#/components/schemas/FaqInput' }],
      },
      DiscussionInput: {
        type: 'object',
        required: ['author_name', 'content'],
        properties: {
          game_id: { type: 'integer', nullable: true, example: 1 },
          author_name: { type: 'string', example: 'Sam' },
          content: { type: 'string', example: 'Cashout is taking longer today.' },
          parent_id: { type: 'integer', nullable: true, example: 4 },
          approved: { type: 'boolean', example: true },
        },
      },
      DiscussionPatch: {
        allOf: [{ $ref: '#/components/schemas/DiscussionInput' }],
      },
      TaskInput: {
        type: 'object',
        required: ['game_id', 'credential_id', 'action', 'username'],
        properties: {
          game_id: { type: 'integer', example: 1 },
          credential_id: { type: 'integer', example: 2 },
          action: { type: 'string', example: 'login' },
          username: { type: 'string', example: 'player01' },
        },
      },
      RegisterInput: {
        type: 'object',
        required: ['email', 'password', 'confirmPassword'],
        properties: {
          email: { type: 'string', format: 'email', example: 'user@example.com' },
          password: { type: 'string', example: 'secret123' },
          confirmPassword: { type: 'string', example: 'secret123' },
        },
      },
      LoginInput: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email', example: 'admin@example.com' },
          password: { type: 'string', example: 'admin123' },
        },
      },
    },
  },
};
