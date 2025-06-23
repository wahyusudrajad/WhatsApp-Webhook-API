const request = require('supertest');

jest.mock('../supabaseClient', () => {
  const signUpMock = jest.fn();
  const signInWithPasswordMock = jest.fn();
  const signOutMock = jest.fn();
  const getUserMock = jest.fn();

  return {
    auth: {
      signUp: signUpMock,
      signInWithPassword: signInWithPasswordMock,
      signOut: signOutMock,
      getUser: getUserMock,
    },
    from: () => ({ select: () => ({}) }), 
  };
});

const supabase = require('../supabaseClient');
const { app } = require('../whatsapp-service');

describe('Authentication Routes', () => {
  afterEach(() => jest.clearAllMocks());

  describe('POST /register', () => {
    it('should validate missing fields', async () => {
      const res = await request(app).post('/register').send({});
      expect(res.statusCode).toBe(200);
      expect(res.text).toContain('All fields are required');
      expect(supabase.auth.signUp).not.toHaveBeenCalled();
    });

    it('should validate password mismatch', async () => {
      const res = await request(app).post('/register').send({
        name: 'Test',
        email: 'test@example.com',
        password: 'pass123',
        confirmPassword: 'different',
      });
      expect(res.statusCode).toBe(200);
      expect(res.text).toContain('Passwords do not match');
      expect(supabase.auth.signUp).not.toHaveBeenCalled();
    });

    it('should register and redirect on success', async () => { 
      supabase.auth.signUp.mockResolvedValue({
        data: { session: { access_token: 'token', expires_in: 3600 } },
        error: null,
      });

      const res = await request(app)
        .post('/register')
        .send({
          name: 'Test',
          email: 'success@example.com',
          password: 'pass123',
          confirmPassword: 'pass123',
        });

      expect(supabase.auth.signUp).toHaveBeenCalled();
      expect(res.statusCode).toBe(302);
      expect(res.headers.location).toBe('/dashboard');
      expect(res.headers['set-cookie']).toBeDefined();
    });
  });

  describe('POST /login', () => {
    it('should login and redirect to dashboard', async () => {
      supabase.auth.signInWithPassword.mockResolvedValue({
        data: { session: { access_token: 'token', expires_in: 3600 } },
        error: null,
      });

      const res = await request(app)
        .post('/login')
        .send({ email: 'login@example.com', password: 'pass123' });

      expect(supabase.auth.signInWithPassword).toHaveBeenCalled();
      expect(res.statusCode).toBe(302);
      expect(res.headers.location).toBe('/dashboard');
    });

    it('should return error on invalid credentials', async () => {
      supabase.auth.signInWithPassword.mockResolvedValue({
        data: null,
        error: { message: 'Invalid login' },
      });

      const res = await request(app)
        .post('/login')
        .send({ email: 'fail@example.com', password: 'wrong' });

      expect(res.statusCode).toBe(200);
      expect(res.text).toContain('Invalid login');
    });
  });
}); 