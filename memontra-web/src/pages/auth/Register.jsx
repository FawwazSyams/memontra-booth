// src/pages/auth/Register.jsx
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const Register = () => {
    // State untuk menangkap inputan user
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [password_confirmation, setPasswordConfirmation] = useState('');

    // State untuk status submit dan error
    const [errors, setErrors] = useState({});
    const [isSubmitting, setIsSubmitting] = useState(false);

    const { register } = useAuth();
    const navigate = useNavigate();

    // Fungsi saat form disubmit
    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        setErrors({}); // Reset error

        // Kirim data ke fungsi register di context
        const success = await register({
            name,
            email,
            password,
            password_confirmation,
            setErrors
        });

        if (success) {
            // Jika berhasil daftar, Laravel biasanya langsung meloginkan user.
            // Kita arahkan ke halaman booking (nanti di sana kita cek status verifikasi emailnya)
            navigate('/booking');
        }

        setIsSubmitting(false);
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-primary/5 px-4 py-12 font-poppins">
            <div className="max-w-md w-full bg-universal rounded-3xl shadow-xl p-8 border border-gray-100">

                <div className="text-center mb-8">
                    <Link to="/" className="text-2xl font-bold text-primary inline-block mb-2">
                        MEMONTRA <span className="text-secondary">BOOTH</span>
                    </Link>
                    <h2 className="text-2xl font-bold text-dark mt-4">Buat Akun Baru</h2>
                    <p className="text-dark/60 text-sm mt-2">Daftar untuk mulai mengatur pesanan photobooth-mu.</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">

                    {/* Input Nama */}
                    <div>
                        <label className="block text-sm font-medium text-dark/80 mb-1">Nama Lengkap</label>
                        <input
                            type="text"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            className={`w-full px-4 py-3 rounded-xl border outline-none transition-all ${errors.name ? 'border-red-500 focus:ring-2 focus:ring-red-200' : 'border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20'
                                }`}
                            placeholder="Masukkan nama Anda"
                            required
                        />
                        {errors.name && <span className="text-red-500 text-xs mt-1 block">{errors.name[0]}</span>}
                    </div>

                    {/* Input Email */}
                    <div>
                        <label className="block text-sm font-medium text-dark/80 mb-1">Email</label>
                        <input
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            className={`w-full px-4 py-3 rounded-xl border outline-none transition-all ${errors.email ? 'border-red-500 focus:ring-2 focus:ring-red-200' : 'border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20'
                                }`}
                            placeholder="contoh@email.com"
                            required
                        />
                        {errors.email && <span className="text-red-500 text-xs mt-1 block">{errors.email[0]}</span>}
                    </div>

                    {/* Input Password */}
                    <div>
                        <label className="block text-sm font-medium text-dark/80 mb-1">Password</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className={`w-full px-4 py-3 rounded-xl border outline-none transition-all ${errors.password ? 'border-red-500 focus:ring-2 focus:ring-red-200' : 'border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20'
                                }`}
                            placeholder="Minimal 8 karakter"
                            required
                        />
                        {errors.password && <span className="text-red-500 text-xs mt-1 block">{errors.password[0]}</span>}
                    </div>

                    {/* Input Konfirmasi Password */}
                    <div>
                        <label className="block text-sm font-medium text-dark/80 mb-1">Konfirmasi Password</label>
                        <input
                            type="password"
                            value={password_confirmation}
                            onChange={(e) => setPasswordConfirmation(e.target.value)}
                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                            placeholder="Ulangi password"
                            required
                        />
                    </div>

                    {/* Tombol Daftar */}
                    <button
                        type="submit"
                        disabled={isSubmitting}
                        className={`w-full font-bold py-3.5 rounded-xl shadow-md transition-all duration-300 mt-4 flex justify-center items-center ${isSubmitting ? 'bg-primary/70 text-universal cursor-not-allowed' : 'bg-primary text-universal hover:bg-opacity-90 hover:-translate-y-0.5'
                            }`}
                    >
                        {isSubmitting ? (
                            <svg className="animate-spin h-5 w-5 text-universal" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                        ) : (
                            "Daftar Sekarang"
                        )}
                    </button>
                </form>

                <div className="flex items-center my-6">
                    <div className="grow border-t border-gray-200"></div>
                    <span className="px-4 text-xs text-dark/40 font-medium uppercase">Atau daftar dengan</span>
                    <div className="grow border-t border-gray-200"></div>
                </div>

                {/* Tombol Register Google */}
                <button
                    type="button"
                    className="w-full flex items-center justify-center gap-3 bg-universal border-2 border-gray-200 text-dark font-semibold py-3.5 rounded-xl hover:bg-gray-50 hover:border-gray-300 transition-all duration-300"
                >
                    <svg className="w-5 h-5" viewBox="0 0 24 24">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
                    </svg>
                    Google
                </button>

                <p className="text-center text-sm text-dark/70 mt-8">
                    Sudah punya akun? <Link to="/login" className="text-primary font-bold hover:text-secondary transition-colors">Masuk di sini</Link>
                </p>

            </div>
        </div>
    );
};

export default Register;