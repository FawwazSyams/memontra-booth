import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import axios from '../lib/axios';
import Navbar from '../components/layouts/Navbar';
import Footer from '../components/layouts/Footer';

const Booking = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();

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

    // Injeksi Midtrans Snap.js
    useEffect(() => {
        const midtransScriptUrl = 'https://app.sandbox.midtrans.com/snap/snap.js';
        const clientKey = import.meta.env.VITE_MIDTRANS_CLIENT_KEY || 'SB-Mid-client-YOUR_KEY_HERE';

        let scriptTag = document.createElement('script');
        scriptTag.src = midtransScriptUrl;
        scriptTag.setAttribute('data-client-key', clientKey);
        
        document.body.appendChild(scriptTag);
        
        return () => {
            if(document.body.contains(scriptTag)) {
                document.body.removeChild(scriptTag);
            }
        }
    }, []);

    const handleLogout = async () => {
        await logout();
        navigate('/login');
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
            const snapToken = response.data.snap_token;

            if (snapToken) {
                // Munculkan popup dari Midtrans
                window.snap.pay(snapToken, {
                    onSuccess: function(result){
                        alert("Pembayaran berhasil!");
                        navigate('/riwayat-booking');
                    },
                    onPending: function(result){
                        alert("Menunggu pembayaran Anda!");
                        navigate('/riwayat-booking');
                    },
                    onError: function(result){
                        alert("Pembayaran gagal!");
                        navigate('/riwayat-booking');
                    },
                    onClose: function(){
                        alert("Anda menutup popup pembayaran sebelum menyelesaikannya.");
                        navigate('/riwayat-booking');
                    }
                });
            } else {
                alert('Pesanan berhasil dibuat, tapi gagal memuat proses pembayaran.');
                navigate('/riwayat-booking');
            }

        } catch (error) {
            console.error("Gagal melakukan booking:", error);
            alert('Waduh, terjadi kesalahan saat menyimpan pesanan. Coba lagi ya.');
        } finally {
            setIsSubmitting(false);
        }
    };

    const packagesList = [
        {
            name: 'Silver',
            duration: '2 Jam',
            price: 'Rp 600.000',
            benefits: ['Unlimited Foto', 'Custom Template 1 Desain', 'Softcopy via GDrive', '1 Fotografer & 1 Asisten']
        },
        {
            name: 'Gold',
            duration: '4 Jam',
            price: 'Rp 1.000.000',
            benefits: ['Unlimited Foto & Cetak', 'Custom Template 2 Desain', 'Scrapbook / Guest Book', 'Softcopy Flashdisk', 'Props & Aksesoris Unik']
        },
        {
            name: 'Platinum',
            duration: '6 Jam',
            price: 'Rp 1.500.000',
            benefits: ['Layanan Maksimal Seharian', 'Custom Backdrop Premium', 'Frame Foto Eksklusif', 'Scrapbook Premium', 'Video Highlight 1 Menit']
        }
    ];

    return (
        <div className="flex flex-col min-h-screen bg-primary/5 font-poppins">
            <Navbar />
            
            <main className="grow pt-32 pb-16 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto w-full relative z-10">

                {/* Header Dashboard */}
                <div className="bg-universal rounded-3xl shadow-sm p-6 sm:p-8 mb-8 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border border-gray-100">
                    <div>
                        <h1 className="text-2xl sm:text-3xl font-bold text-dark">Dashboard Pemesanan</h1>
                        <p className="text-dark/60 mt-1">Halo, <span className="font-semibold text-primary">{user?.name || 'Klien'}</span>! Mari atur pesanan photobooth acaramu.</p>
                    </div>
                </div>

                {/* Tampilan Form Booking Utama */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

                        {/* Kiri: Form Input (Porsi lebih besar) */}
                        <div className="lg:col-span-2 bg-universal rounded-3xl shadow-sm p-6 sm:p-8 border border-gray-100">
                            <h2 className="text-xl font-bold text-primary mb-6 border-b border-gray-100 pb-4">Lengkapi Detail Acara</h2>

                            <form onSubmit={handleBookingSubmit} className="space-y-8">

                                {/* 1. Pemilihan Paket */}
                                <div>
                                    <label className="block text-sm font-semibold text-dark mb-3">1. Pilih Paket Photobooth</label>
                                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 items-start">
                                        {packagesList.map((pkg) => {
                                            const isSelected = formData.package === pkg.name;
                                            return (
                                                <div
                                                    key={pkg.name}
                                                    onClick={() => setFormData({ ...formData, package: isSelected ? '' : pkg.name })}
                                                    className={`cursor-pointer rounded-2xl border-2 transition-all duration-300 overflow-hidden ${isSelected
                                                        ? 'border-primary bg-primary/5 shadow-md'
                                                        : 'border-gray-200 hover:border-primary/50 hover:bg-gray-50'
                                                        }`}
                                                >
                                                    <div className="p-4 text-center">
                                                        <h3 className={`font-bold ${isSelected ? 'text-primary' : 'text-dark'}`}>{pkg.name}</h3>
                                                        <p className="text-xs text-dark/60 mt-1">{pkg.duration}</p>
                                                    </div>
                                                    
                                                    {/* Expandable Benefits */}
                                                    <div className={`transition-all duration-300 ease-in-out ${isSelected ? 'max-h-[300px] opacity-100 pb-4' : 'max-h-0 opacity-0'} px-4 overflow-hidden`}>
                                                        <div className="h-px w-full bg-primary/20 mb-3"></div>
                                                        <p className="text-primary font-bold text-center mb-2">{pkg.price}</p>
                                                        <ul className="space-y-1.5">
                                                            {pkg.benefits.map((benefit, i) => (
                                                                <li key={i} className="text-xs text-dark/70 flex items-start gap-1.5 text-left leading-relaxed">
                                                                    <span className="text-primary shrink-0">✓</span> {benefit}
                                                                </li>
                                                            ))}
                                                        </ul>
                                                    </div>
                                                </div>
                                            );
                                        })}
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
            </main>
            <Footer />
        </div>
    );
};

export default Booking;