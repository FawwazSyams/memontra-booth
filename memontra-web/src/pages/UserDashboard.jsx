import React from 'react';
import Navbar from '../components/layouts/Navbar';
import Footer from '../components/layouts/Footer';
import { useAuth } from '../context/AuthContext';
import { Link } from 'react-router-dom';

const UserDashboard = () => {
    const { user } = useAuth();

    return (
        <div className="flex flex-col min-h-screen bg-primary/5 font-poppins">
            <Navbar />

            <main className="grow pt-32 pb-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full relative z-10">
                {/* Header Welcome */}
                <div className="bg-universal rounded-3xl shadow-sm p-8 border border-gray-100 flex flex-col md:flex-row items-center justify-between gap-6 mb-8 relative overflow-hidden">
                    <div className="absolute -right-20 -top-20 w-64 h-64 bg-primary/10 rounded-full blur-3xl pointer-events-none"></div>
                    <div className="absolute -left-20 -bottom-20 w-64 h-64 bg-secondary/10 rounded-full blur-3xl pointer-events-none"></div>

                    <div className="relative z-10 w-full md:w-auto text-center md:text-left">
                        <h1 className="text-3xl md:text-4xl font-extrabold text-dark mb-3 tracking-tight">
                            Selamat Datang, <span className="text-primary">{user?.name.split(" ")[0]}!</span>
                        </h1>
                        <p className="text-dark/60 text-lg md:text-xl">
                            Siap untuk mengabadikan momen spesial Anda hari ini?
                        </p>
                    </div>
                    <div className="relative z-10 shrink-0 w-full md:w-auto">
                        <Link to="/booking" className="w-full md:w-auto justify-center bg-primary text-universal px-8 py-4 rounded-2xl font-bold shadow-lg shadow-primary/30 hover:-translate-y-1 hover:shadow-primary/50 transition-all flex items-center gap-3">
                            Mulai Booking
                        </Link>
                    </div>
                </div>

                {/* Quick Menu Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
                    <Link to="/booking" className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-xl hover:shadow-blue-500/10 hover:border-blue-300 group transition-all duration-300">
                        <div className="w-16 h-16 bg-linear-to-br from-blue-50 to-blue-100 text-blue-500 rounded-2xl flex items-center justify-center text-3xl mb-5 group-hover:scale-110 transition-transform duration-300 shadow-inner">🎛️</div>
                        <h3 className="font-bold text-xl text-dark mb-2 group-hover:text-blue-600 transition-colors">Dashboard Pemesanan</h3>
                        <p className="text-sm text-dark/70 leading-relaxed">Atur pemesanan photobooth Anda, pilih paket, dan tentukan lokasi acara dengan mudah dan cepat.</p>
                    </Link>

                    <Link to="/riwayat-booking" className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-xl hover:shadow-orange-500/10 hover:border-orange-300 group transition-all duration-300">
                        <div className="w-16 h-16 bg-linear-to-br from-orange-50 to-orange-100 text-orange-500 rounded-2xl flex items-center justify-center text-3xl mb-5 group-hover:scale-110 transition-transform duration-300 shadow-inner">📅</div>
                        <h3 className="font-bold text-xl text-dark mb-2 group-hover:text-orange-600 transition-colors">Riwayat Pesanan</h3>
                        <p className="text-sm text-dark/70 leading-relaxed">Pantau status pesanan, lihat detail jadwal, dan kelola semua riwayat pemesanan Anda di satu tempat.</p>
                    </Link>
                </div>

                {/* Recent Activity Section */}
                <div>
                    <div className="flex justify-between items-end mb-6">
                        <div>
                            <h2 className="text-2xl font-extrabold text-dark tracking-tight">Aktivitas Terakhir</h2>
                            <p className="text-dark/60 mt-1">Ringkasan kegiatan terbaru di akun Anda.</p>
                        </div>
                        <Link to="/riwayat-booking" className="text-primary font-bold hover:text-secondary hover:underline transition-colors hidden sm:block">Lihat Semua →</Link>
                    </div>

                    {/* Empty State / Placeholder */}
                    <div className="bg-universal rounded-3xl border border-dashed border-gray-300 flex flex-col justify-center items-center py-16 px-6 text-center">
                        <div className="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center text-5xl mb-5 border border-gray-100 shadow-inner">
                            ☁️
                        </div>
                        <h3 className="font-bold text-dark text-xl mb-2">Belum Ada Aktivitas</h3>
                        <p className="text-dark/60 text-sm max-w-md mx-auto mb-8">Anda belum memiliki riwayat pemesanan atau aktivitas apapun. Yuk buat momen pertamamu bersama Memontra!</p>
                        <Link to="/booking" className="bg-primary/10 text-primary font-extrabold px-8 py-3.5 rounded-xl hover:bg-primary hover:text-universal transition-all hover:shadow-lg hover:shadow-primary/20">
                            Booking Sekarang
                        </Link>
                    </div>
                </div>

            </main>

            <Footer />
        </div>
    );
};

export default UserDashboard;
