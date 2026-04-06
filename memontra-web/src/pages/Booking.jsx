// src/pages/Booking.jsx
import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import axios from '../lib/axios';

const Booking = () => {
    const { user, logout, resendVerification } = useAuth();
    const navigate = useNavigate();

    const [resendStatus, setResendStatus] = useState({ loading: false, message: '', isSuccess: false });

    // State untuk form booking
    const [formData, setFormData] = useState({
        package: '',
        date: '',
        time: '',
        city: 'Bandung',
        address: '',
        eventType: 'Pernikahan',
        notes: ''
    });

    const handleLogout = async () => {
        await logout();
        navigate('/login');
    };

    const handleResendEmail = async () => {
        setResendStatus({ loading: true, message: '', isSuccess: false });
        const result = await resendVerification();
        setResendStatus({ loading: false, message: result.message, isSuccess: result.success });
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const [isSubmitting, setIsSubmitting] = useState(false);

    const handleBookingSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);

        try {
            // Tembak endpoint API Laravel
            const response = await axios.post('/api/bookings', formData);

            // Jika berhasil
            alert('Mantap! Pesanan berhasil dibuat. Tim kami akan segera menghubungi kamu.');

            // Kosongkan form setelah sukses (opsional)
            setFormData({
                package: '', date: '', time: '', city: 'Bandung', address: '', eventType: 'Pernikahan'
            });

        } catch (error) {
            console.error("Gagal melakukan booking:", error);
            alert('Waduh, terjadi kesalahan saat menyimpan pesanan. Coba lagi ya.');
        } finally {
            setIsSubmitting(false);
        }
    };

    // Cek verifikasi (Untuk testing UI, kamu bisa ubah ini sementara jadi "true" kalau mau lihat formnya)
    const isEmailVerified = user?.email_verified_at !== null;

    return (
        <div className="min-h-screen bg-primary/5 p-4 sm:p-8 font-poppins pb-20">
            <div className="max-w-5xl mx-auto">

                {/* Header Dashboard */}
                <div className="bg-universal rounded-3xl shadow-sm p-6 sm:p-8 mb-8 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border border-gray-100">
                    <div>
                        <h1 className="text-2xl sm:text-3xl font-bold text-dark">Dashboard Pemesanan</h1>
                        <p className="text-dark/60 mt-1">Halo, <span className="font-semibold text-primary">{user?.name || 'Klien'}</span>! Mari atur acaramu.</p>
                    </div>
                    <button
                        onClick={handleLogout}
                        className="bg-red-50 text-red-600 hover:bg-red-100 px-6 py-2 rounded-xl font-semibold transition-colors w-full sm:w-auto text-sm"
                    >
                        Keluar Akun
                    </button>
                </div>

                {!isEmailVerified ? (
                    /* Tampilan Jika Belum Verifikasi */
                    <div className="bg-universal rounded-3xl shadow-sm p-8 text-center border border-gray-100">
                        <div className="w-16 h-16 bg-secondary/20 text-secondary rounded-full flex items-center justify-center mx-auto mb-4 text-3xl">✉️</div>
                        <h2 className="text-xl font-bold text-dark mb-2">Verifikasi Email Kamu Dulu Yuk!</h2>
                        <p className="text-dark/70 mb-6 max-w-md mx-auto text-sm">
                            Kami telah mengirimkan link verifikasi ke <span className="font-semibold">{user?.email}</span>. Silakan klik link tersebut untuk mulai memesan.
                        </p>
                        {resendStatus.message && (
                            <div className={`mb-4 p-3 rounded-lg text-sm font-medium ${resendStatus.isSuccess ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-600'}`}>
                                {resendStatus.message}
                            </div>
                        )}
                        <button onClick={handleResendEmail} disabled={resendStatus.loading} className="bg-primary text-universal font-semibold py-3 px-6 rounded-xl hover:bg-opacity-90 transition shadow-md">
                            {resendStatus.loading ? 'Mengirim...' : 'Kirim Ulang Email Verifikasi'}
                        </button>
                    </div>
                ) : (

                    /* Tampilan Form Booking Utama */
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

                        {/* Kiri: Form Input (Porsi lebih besar) */}
                        <div className="lg:col-span-2 bg-universal rounded-3xl shadow-sm p-6 sm:p-8 border border-gray-100">
                            <h2 className="text-xl font-bold text-primary mb-6 border-b border-gray-100 pb-4">Lengkapi Detail Acara</h2>

                            <form onSubmit={handleBookingSubmit} className="space-y-8">

                                {/* 1. Pemilihan Paket */}
                                <div>
                                    <label className="block text-sm font-semibold text-dark mb-3">1. Pilih Paket Photobooth</label>
                                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                        {['Silver', 'Gold', 'Platinum'].map((pkg) => (
                                            <div
                                                key={pkg}
                                                onClick={() => setFormData({ ...formData, package: pkg })}
                                                className={`cursor-pointer rounded-2xl p-4 border-2 transition-all duration-300 text-center ${formData.package === pkg
                                                    ? 'border-primary bg-primary/10 shadow-md'
                                                    : 'border-gray-200 hover:border-primary/50 hover:bg-gray-50'
                                                    }`}
                                            >
                                                <h3 className={`font-bold ${formData.package === pkg ? 'text-primary' : 'text-dark'}`}>{pkg}</h3>
                                                <p className="text-xs text-dark/60 mt-1">{pkg === 'Silver' ? '2 Jam' : pkg === 'Gold' ? '4 Jam' : '6 Jam'}</p>
                                            </div>
                                        ))}
                                    </div>
                                </div>

                                {/* 2. Tanggal & Waktu */}
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    <div>
                                        <label className="block text-sm font-semibold text-dark mb-2">2. Tanggal Acara</label>
                                        <input
                                            type="date"
                                            name="date"
                                            value={formData.date}
                                            onChange={handleInputChange}
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-dark/80"
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-semibold text-dark mb-2">Waktu Mulai (Standby)</label>
                                        <input
                                            type="time"
                                            name="time"
                                            value={formData.time}
                                            onChange={handleInputChange}
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-dark/80"
                                            required
                                        />
                                    </div>
                                </div>

                                {/* 3. Lokasi & Jenis Acara */}
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                    <div>
                                        <label className="block text-sm font-semibold text-dark mb-2">3. Area Layanan</label>
                                        <select
                                            name="city"
                                            value={formData.city}
                                            onChange={handleInputChange}
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none bg-universal"
                                        >
                                            <option value="Bandung">Kota Bandung</option>
                                            <option value="Cimahi">Kota Cimahi</option>
                                            <option value="Kab. Bandung">Kabupaten Bandung</option>
                                            <option value="Kab. Bandung Barat">Kab. Bandung Barat</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-semibold text-dark mb-2">Jenis Acara</label>
                                        <select
                                            name="eventType"
                                            value={formData.eventType}
                                            onChange={handleInputChange}
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none bg-universal"
                                        >
                                            <option value="Pernikahan">Pernikahan (Wedding)</option>
                                            <option value="Ulang Tahun">Ulang Tahun</option>
                                            <option value="Perpisahan Sekolah">Perpisahan Sekolah / Wisuda</option>
                                            <option value="Corporate Event">Acara Kantor (Corporate)</option>
                                            <option value="Lainnya">Lainnya</option>
                                        </select>
                                    </div>
                                </div>

                                {/* Alamat Detail */}
                                <div>
                                    <label className="block text-sm font-semibold text-dark mb-2">Alamat Lengkap Venue / Gedung</label>
                                    <textarea
                                        name="address"
                                        value={formData.address}
                                        onChange={handleInputChange}
                                        rows="3"
                                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none resize-none"
                                        placeholder="Contoh: Gedung Sate, Jl. Diponegoro No.22..."
                                        required
                                    ></textarea>
                                </div>

                                {/* Tombol Submit Kelihatan di HP, Sembunyi di Desktop */}
                                <div className="lg:hidden">
                                    <button type="submit" className="w-full bg-primary text-universal font-bold py-4 rounded-xl shadow-md hover:bg-opacity-90 transition-all">
                                        Konfirmasi Pesanan
                                    </button>
                                </div>
                            </form>
                        </div>

                        {/* Kanan: Ringkasan Pesanan (Sticky / Tetap di posisi saat di-scroll) */}
                        <div className="lg:col-span-1">
                            <div className="bg-universal rounded-3xl shadow-sm p-6 border border-gray-100 sticky top-28">
                                <h3 className="font-bold text-lg text-dark mb-4 border-b border-gray-100 pb-4">Ringkasan Pesanan</h3>

                                <div className="space-y-4 mb-6 text-sm">
                                    <div className="flex justify-between">
                                        <span className="text-dark/60">Paket:</span>
                                        <span className="font-semibold text-primary">{formData.package || '-'}</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-dark/60">Tanggal:</span>
                                        <span className="font-medium text-dark">{formData.date || '-'}</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-dark/60">Lokasi:</span>
                                        <span className="font-medium text-dark">{formData.city}</span>
                                    </div>
                                </div>

                                <div className="bg-primary/5 p-4 rounded-xl mb-6 border border-primary/10">
                                    <p className="text-xs text-dark/70 leading-relaxed">
                                        *Tim Memontra Booth akan tiba 1 jam sebelum acara dimulai untuk melakukan *setup* peralatan.
                                    </p>
                                </div>

                                {/* Tombol Submit (Desktop) */}
                                <button
                                    onClick={handleBookingSubmit}
                                    disabled={isSubmitting || !formData.package || !formData.date || !formData.address}
                                    className={`hidden lg:block w-full font-bold py-3.5 rounded-xl shadow-md transition-all duration-300 ${!formData.package || !formData.date || !formData.address
                                        ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                                        : 'bg-primary text-universal hover:bg-opacity-90 hover:-translate-y-1'
                                        }`}
                                >
                                    Konfirmasi Booking
                                </button>
                            </div>
                        </div>

                    </div>
                )}
            </div>
        </div>
    );
};

export default Booking;