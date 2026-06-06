import React, { useState } from 'react';
import Navbar from '../components/layouts/Navbar';
import Footer from '../components/layouts/Footer';
import { useAuth } from '../context/AuthContext';
import { Link } from 'react-router-dom';

const RiwayatBooking = () => {
    const { user } = useAuth();

    // Data riwayat pesanan (kosong untuk saat ini)
    const historyData = [];

    return (
        <div className="flex flex-col min-h-screen bg-primary/5 font-poppins">
            <Navbar />
            
            <main className="grow pt-32 pb-16 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto w-full relative z-10">
                {/* Header Section */}
                <div className="mb-10 text-center sm:text-left">
                    <h1 className="text-3xl sm:text-4xl font-extrabold text-dark tracking-tight">Riwayat Pesanan</h1>
                    <p className="text-dark/60 mt-2 text-lg">Pantau dan kelola semua transaksi photobooth Anda di sini.</p>
                </div>

                {/* List Riwayat */}
                <div className="space-y-6">
                    {historyData.length > 0 ? (
                        historyData.map((item, index) => (
                            <div key={index} className="bg-universal rounded-3xl p-6 sm:p-8 shadow-sm border border-gray-100 hover:shadow-lg hover:border-primary/20 transition-all duration-300 group">
                                <div className="flex flex-col sm:flex-row justify-between items-start gap-4 mb-6 pb-6 border-b border-gray-100">
                                    <div>
                                        <div className="flex items-center gap-3 mb-2">
                                            <span className="font-bold text-dark/50 text-sm uppercase tracking-wider">{item.id}</span>
                                        </div>
                                        <h3 className="text-xl sm:text-2xl font-bold text-primary">{item.package} Package</h3>
                                        <p className="text-dark/70 text-sm mt-1">Acara {item.event} • Durasi {item.duration}</p>
                                    </div>
                                    <div className="text-left sm:text-right">
                                        <p className="text-sm text-dark/50 mb-1">Total Tagihan</p>
                                        <p className="text-2xl font-extrabold text-dark">{item.price}</p>
                                    </div>
                                </div>
                                
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    <div className="flex items-start gap-3">
                                        <div className="w-10 h-10 rounded-xl bg-orange-50 text-orange-500 flex items-center justify-center shrink-0">📅</div>
                                        <div>
                                            <p className="text-xs text-dark/50 font-semibold mb-0.5">Tanggal Acara</p>
                                            <p className="font-bold text-dark text-sm">{item.date}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-start gap-3">
                                        <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-500 flex items-center justify-center shrink-0">📍</div>
                                        <div>
                                            <p className="text-xs text-dark/50 font-semibold mb-0.5">Lokasi</p>
                                            <p className="font-bold text-dark text-sm line-clamp-1">{item.location}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))
                    ) : (
                        <div className="bg-universal rounded-3xl border border-dashed border-gray-300 flex flex-col justify-center items-center py-16 px-6 text-center">
                            <div className="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center text-5xl mb-5 opacity-50 grayscale">
                                📭
                            </div>
                            <h3 className="font-bold text-dark text-xl mb-2">Tidak Ada Riwayat</h3>
                            <p className="text-dark/60 text-sm max-w-md mx-auto mb-6">Anda belum memiliki riwayat pesanan apapun.</p>
                            <Link to="/booking" className="bg-primary/10 text-primary font-extrabold px-6 py-3 rounded-xl hover:bg-primary hover:text-universal transition-all">
                                Buat Pesanan Baru
                            </Link>
                        </div>
                    )}
                </div>
            </main>
            
            <Footer />
        </div>
    );
};

export default RiwayatBooking;
