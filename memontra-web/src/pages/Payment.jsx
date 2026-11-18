import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import Navbar from '../components/layouts/Navbar';
import Footer from '../components/layouts/Footer';
import axios from '../lib/axios';

const Payment = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const booking = location.state?.booking;
    const snapToken = location.state?.snapToken;
    const paymentUrl = location.state?.paymentUrl || (snapToken && snapToken.startsWith('http') ? snapToken : null);

    const [isSimulating, setIsSimulating] = useState(false);

    useEffect(() => {
        if (!booking) {
            navigate('/riwayat-booking');
        }
    }, [booking, navigate]);

    const handlePayDoku = () => {
        if (paymentUrl) {
            // Arahkan ke halaman DOKU Checkout
            window.location.href = paymentUrl;
        } else if (booking?.snap_token && booking.snap_token.startsWith('http')) {
            window.location.href = booking.snap_token;
        } else {
            alert('Mengalihkan ke gateway pembayaran DOKU...');
            // Fallback jika paymentUrl simulasi
            window.open(`https://momentrabooth.com/payment?booking_id=${booking?.id}`, '_blank');
        }
    };

    const handleSimulatePayment = async () => {
        if (!booking) return;
        setIsSimulating(true);
        try {
            await axios.put(`/api/bookings/${booking.id}/pay`);
            alert('Simulasi pembayaran berhasil! Status pesanan kini telah lunas (Paid).');
            navigate('/riwayat-booking');
        } catch (e) {
            try {
                await axios.put(`/api/bookings/${booking.id}/pay-public`);
                alert('Simulasi pembayaran berhasil! Status pesanan kini telah lunas (Paid).');
                navigate('/riwayat-booking');
            } catch (err) {
                console.error(err);
                alert('Gagal memperbarui status pembayaran: ' + (err.response?.data?.message || err.message));
            }
        } finally {
            setIsSimulating(false);
        }
    };

    if (!booking) return null;

    return (
        <div className="flex flex-col min-h-screen bg-[#F8FAFC] font-poppins">
            <Navbar />
            
            <main className="grow pt-32 pb-16 px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto w-full relative z-10 flex flex-col justify-center">
                <div className="bg-white rounded-[32px] p-8 md:p-12 shadow-xl border border-gray-100 text-center relative overflow-hidden">
                    <div className="absolute -top-24 -right-24 w-64 h-64 bg-primary/5 rounded-full blur-3xl -z-10"></div>
                    <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-red-500/5 rounded-full blur-3xl -z-10"></div>
                    
                    {/* DOKU Header Badge */}
                    <div className="inline-flex items-center gap-2 bg-red-50 text-red-600 px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider mb-4 border border-red-100">
                        <span className="w-2 h-2 rounded-full bg-red-600 animate-pulse"></span>
                        DOKU Payment Gateway
                    </div>

                    <h1 className="text-3xl font-extrabold text-gray-900 mb-2">Selesaikan Pembayaran</h1>
                    <p className="text-gray-500 mb-8 text-sm">Pesanan photobooth Anda siap diproses setelah pembayaran terverifikasi.</p>

                    {/* Order Summary Card */}
                    <div className="bg-gray-50/90 rounded-[24px] p-6 text-left space-y-4 mb-8 border border-gray-100">
                        <div className="flex justify-between items-center pb-4 border-b border-gray-200 border-dashed">
                            <span className="text-gray-500 font-medium">Order ID</span>
                            <span className="font-bold text-gray-800">INV-MB-{booking.id}</span>
                        </div>
                        <div className="flex justify-between items-center pb-4 border-b border-gray-200 border-dashed">
                            <span className="text-gray-500 font-medium">Paket Photobooth</span>
                            <span className="font-bold text-gray-800">{booking.package}</span>
                        </div>
                        <div className="flex justify-between items-center pb-4 border-b border-gray-200 border-dashed">
                            <span className="text-gray-500 font-medium">Tanggal Acara</span>
                            <span className="font-bold text-gray-800">{booking.date}</span>
                        </div>
                        <div className="flex justify-between items-center pb-4 border-b border-gray-200 border-dashed">
                            <span className="text-gray-500 font-medium">Waktu / Jam</span>
                            <span className="font-bold text-gray-800">{booking.time}</span>
                        </div>
                        <div className="flex justify-between items-center pb-4 border-b border-gray-200 border-dashed">
                            <span className="text-gray-500 font-medium">Lokasi</span>
                            <span className="font-bold text-gray-800 text-sm max-w-xs text-right truncate">{booking.address}, {booking.city}</span>
                        </div>
                        <div className="flex justify-between items-center pt-2">
                            <span className="text-gray-600 font-semibold">Total Tagihan</span>
                            <span className="text-2xl font-black text-primary">Rp {new Intl.NumberFormat('id-ID').format(booking.total_price)}</span>
                        </div>
                    </div>

                    {/* Supported Payment Channels */}
                    <div className="mb-8 p-4 rounded-2xl bg-slate-50 border border-slate-100 text-xs text-gray-500">
                        <p className="font-semibold text-gray-700 mb-2">Metode Pembayaran Tersedia di DOKU:</p>
                        <div className="flex flex-wrap items-center justify-center gap-2 font-medium">
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">QRIS</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">BCA VA</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">Mandiri</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">BRI</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">BNI</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">GoPay</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">OVO</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">ShopeePay</span>
                            <span className="bg-white px-2.5 py-1 rounded-lg border border-gray-200 text-gray-700">Kartu Kredit/Debit</span>
                        </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="space-y-3">
                        <button 
                            onClick={handlePayDoku}
                            className="w-full bg-gradient-to-r from-red-600 to-rose-600 text-white font-bold py-4 rounded-2xl hover:from-red-700 hover:to-rose-700 hover:-translate-y-0.5 hover:shadow-xl hover:shadow-red-500/25 transition-all duration-300 flex items-center justify-center gap-2 text-base"
                        >
                            <span>Bayar Sekarang via DOKU</span>
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3"/></svg>
                        </button>

                        <button 
                            onClick={handleSimulatePayment}
                            disabled={isSimulating}
                            className="w-full bg-gray-100 text-gray-700 font-semibold py-3 rounded-2xl hover:bg-gray-200 transition-colors text-xs border border-gray-200 flex items-center justify-center gap-2"
                        >
                            <svg className="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                            {isSimulating ? 'Memperbarui...' : 'Simulasi Pembayaran Berhasil (Localhost Testing)'}
                        </button>
                    </div>
                    
                    <p className="text-xs text-gray-400 mt-6 flex items-center justify-center gap-2">
                        <svg className="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/></svg>
                        Pembayaran resmi, aman & terenkripsi oleh DOKU Payment Gateway
                    </p>
                </div>
            </main>
            
            <Footer />
        </div>
    );
};

export default Payment;
