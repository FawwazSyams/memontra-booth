import React, { useState, useEffect } from 'react';
import Navbar from '../components/layouts/Navbar';
import Footer from '../components/layouts/Footer';
import { useAuth } from '../context/AuthContext';
import { Link, useNavigate } from 'react-router-dom';
import axios from '../lib/axios';
import {
    FaHome,
    FaHistory,
    FaCamera,
    FaClock,
    FaCheckCircle,
    FaExclamationCircle,
    FaCreditCard,
    FaArrowRight,
    FaUserCheck,
    FaCalendarAlt,
    FaMapMarkerAlt,
    FaShoppingBag,
    FaRegSmileBeam
} from 'react-icons/fa';

const UserDashboard = () => {
    const { user } = useAuth();
    const navigate = useNavigate();

    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all'); // 'all', 'pending', 'paid'
    const [simulatingId, setSimulatingId] = useState(null);

    useEffect(() => {
        let isMounted = true;
        const load = async () => {
            try {
                const response = await axios.get('/api/my-bookings');
                if (isMounted) {
                    setBookings(response.data || []);
                }
            } catch (error) {
                console.error("Error fetching bookings:", error);
            } finally {
                if (isMounted) {
                    setLoading(false);
                }
            }
        };
        load();
        return () => {
            isMounted = false;
        };
    }, []);

    const formatCurrency = (val) => {
        return 'Rp ' + new Intl.NumberFormat('id-ID').format(val || 0);
    };

    const formatDateTime = (dateStr) => {
        if (!dateStr) return '-';
        try {
            const date = new Date(dateStr);
            if (isNaN(date.getTime())) return dateStr;
            return new Intl.DateTimeFormat('id-ID', {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }).format(date);
        } catch {
            return dateStr;
        }
    };

    const handleSimulatePayment = async (bookingId) => {
        setSimulatingId(bookingId);
        try {
            await axios.put(`/api/bookings/${bookingId}/pay`);
            setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, payment_status: 'paid' } : b));
            alert("Simulasi berhasil! Status pesanan Anda kini 'Paid'.");
        } catch (err) {
            console.error("Gagal simulasikan:", err);
            alert("Gagal memperbarui status.");
        } finally {
            setSimulatingId(null);
        }
    };

    const pendingBookings = bookings.filter(b => b.payment_status === 'pending');
    const paidBookings = bookings.filter(b => b.payment_status === 'paid');

    const filteredBookings = bookings.filter(item => {
        if (filter === 'pending') return item.payment_status === 'pending';
        if (filter === 'paid') return item.payment_status === 'paid';
        return true;
    });

    const isLocalhost = typeof window !== 'undefined' &&
        (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1');

    return (
        <div className="flex flex-col min-h-screen bg-primary/5 font-poppins">
            <Navbar />

            <main className="grow pt-32 pb-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto w-full relative z-10">
                {/* Header Welcome */}
                <div className="bg-universal rounded-3xl shadow-sm p-8 border border-gray-100 flex flex-col md:flex-row items-center justify-between gap-6 mb-8 relative overflow-hidden">
                    <div className="absolute -right-20 -top-20 w-64 h-64 bg-primary/10 rounded-full blur-3xl pointer-events-none"></div>
                    <div className="absolute -left-20 -bottom-20 w-64 h-64 bg-secondary/10 rounded-full blur-3xl pointer-events-none"></div>

                    <div className="relative z-10 w-full md:w-auto text-center md:text-left">
                        <h1 className="text-3xl md:text-4xl font-extrabold text-dark mb-2 tracking-tight">
                            Selamat Datang, <span className="text-primary">{user?.name ? user.name.split(" ")[0] : 'Klien'}!</span>
                        </h1>
                        <p className="text-dark/60 text-base md:text-md max-w-xl">
                            Siap untuk mengabadikan momen spesial Anda hari ini? <br />Pantau pesanan dan atur jadwal photobooth Anda dengan mudah.
                        </p>
                    </div>
                    <div className="relative z-10 shrink-0 w-full md:w-auto flex flex-col sm:flex-row gap-3">
                        <Link to="/booking" className="w-full md:w-auto justify-center bg-primary text-universal px-7 py-3.5 rounded-2xl font-bold shadow-lg shadow-primary/30 hover:-translate-y-0.5 hover:shadow-primary/50 transition-all flex items-center gap-2 text-center">
                            Mulai Booking
                        </Link>
                        <Link to="/riwayat-booking" className="w-full md:w-auto justify-center bg-universal text-dark border border-gray-200 px-6 py-3.5 rounded-2xl font-bold hover:bg-gray-50 transition-all flex items-center gap-2 text-center">
                            <FaHistory className="text-sm text-dark/60" /> Riwayat
                        </Link>
                    </div>
                </div>

                {/* Pending Payment Alert Banner */}
                {pendingBookings.length > 0 && (
                    <div className="mb-8 bg-amber-50/90 border border-amber-200 rounded-3xl p-6 sm:p-7 flex flex-col md:flex-row items-center justify-between gap-5 shadow-sm">
                        <div className="flex items-start gap-4">
                            <div className="w-12 h-12 rounded-2xl bg-amber-500 text-white flex items-center justify-center text-xl shrink-0 shadow-sm shadow-amber-300">
                                <FaClock />
                            </div>
                            <div>
                                <h3 className="text-lg font-bold text-amber-900">
                                    Ada {pendingBookings.length} Pesanan Menunggu Pembayaran
                                </h3>
                                <p className="text-sm text-amber-800/80 mt-1 max-w-2xl leading-relaxed">
                                    Segera selesaikan pembayaran untuk paket <span className="font-bold">{pendingBookings[0].package}</span> (INV-MB-{pendingBookings[0].id}) agar jadwal acara Anda tidak terlewat dan langsung dikonfirmasi oleh tim Memontra.
                                </p>
                            </div>
                        </div>
                        <div className="w-full md:w-auto shrink-0 flex gap-2">
                            {pendingBookings[0].snap_token ? (
                                <button
                                    onClick={() => navigate('/payment', { state: { booking: pendingBookings[0], snapToken: pendingBookings[0].snap_token } })}
                                    className="w-full md:w-auto bg-amber-600 hover:bg-amber-700 text-white font-bold px-6 py-3 rounded-xl shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer"
                                >
                                    <FaCreditCard /> Bayar Sekarang
                                </button>
                            ) : (
                                <Link
                                    to="/riwayat-booking"
                                    className="w-full md:w-auto bg-amber-600 hover:bg-amber-700 text-white font-bold px-6 py-3 rounded-xl shadow-md transition-all flex items-center justify-center gap-2"
                                >
                                    Lihat Pesanan
                                </Link>
                            )}
                        </div>
                    </div>
                )}

                {/* Stats Summary Overview */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-10">
                    <div className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm relative overflow-hidden group hover:border-primary/30 transition-all">
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-dark/50 text-xs font-bold uppercase tracking-wider mb-1">Total Pesanan</p>
                                <h3 className="text-3xl font-extrabold text-dark">{bookings.length}</h3>
                            </div>
                            <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center text-xl shadow-inner">
                                <FaShoppingBag />
                            </div>
                        </div>
                        <p className="text-xs text-dark/60 mt-3 font-medium flex items-center gap-1">
                            Sepanjang riwayat akun Anda
                        </p>
                    </div>

                    <div className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm relative overflow-hidden group hover:border-amber-300 transition-all">
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-dark/50 text-xs font-bold uppercase tracking-wider mb-1">Menunggu Bayar</p>
                                <h3 className="text-3xl font-extrabold text-dark">{pendingBookings.length}</h3>
                            </div>
                            <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center text-xl shadow-inner">
                                <FaClock />
                            </div>
                        </div>
                        <p className="text-xs text-amber-700 mt-3 font-semibold">
                            {pendingBookings.length > 0 ? '⚠️ Butuh tindakan pembayaran' : 'Semua tagihan sudah beres'}
                        </p>
                    </div>

                    <div className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm relative overflow-hidden group hover:border-emerald-300 transition-all">
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-dark/50 text-xs font-bold uppercase tracking-wider mb-1">Pesanan Lunas</p>
                                <h3 className="text-3xl font-extrabold text-dark">{paidBookings.length}</h3>
                            </div>
                            <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center text-xl shadow-inner">
                                <FaCheckCircle />
                            </div>
                        </div>
                        <p className="text-xs text-emerald-700 mt-3 font-semibold">
                            Terkonfirmasi & Terjadwal
                        </p>
                    </div>

                    <div className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm relative overflow-hidden group hover:border-purple-300 transition-all">
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-dark/50 text-xs font-bold uppercase tracking-wider mb-1">Status Pengguna</p>
                                <h3 className="text-xl font-extrabold text-dark mt-1 truncate">
                                    {user?.is_admin ? 'Admin' : 'Member'}
                                </h3>
                            </div>
                            <div className="w-12 h-12 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center text-xl shadow-inner">
                                <FaUserCheck />
                            </div>
                        </div>
                        <p className="text-xs text-dark/60 mt-3 font-medium truncate">
                            {user?.email || 'Akun Aktif'}
                        </p>
                    </div>
                </div>

                {/* Quick Menu Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
                    <Link to="/booking" className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-xl hover:shadow-blue-500/10 hover:border-blue-300 group transition-all duration-300">
                        <div className="w-14 h-14 bg-linear-to-br from-blue-50 to-blue-100 text-blue-500 rounded-2xl flex items-center justify-center text-2xl mb-4 group-hover:scale-110 transition-transform duration-300 shadow-inner">
                            <FaHome />
                        </div>
                        <h3 className="font-bold text-lg text-dark mb-1.5 group-hover:text-blue-600 transition-colors">Booking Photobooth</h3>
                        <p className="text-xs sm:text-sm text-dark/70 leading-relaxed">Pilih paket Silver, Gold, atau Platinum untuk acara pernikahan, ulang tahun, atau gathering.</p>
                    </Link>

                    <Link to="/riwayat-booking" className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-xl hover:shadow-orange-500/10 hover:border-orange-300 group transition-all duration-300">
                        <div className="w-14 h-14 bg-linear-to-br from-orange-50 to-orange-100 text-orange-500 rounded-2xl flex items-center justify-center text-2xl mb-4 group-hover:scale-110 transition-transform duration-300 shadow-inner">
                            <FaHistory />
                        </div>
                        <h3 className="font-bold text-lg text-dark mb-1.5 group-hover:text-orange-600 transition-colors">Riwayat & Tagihan</h3>
                        <p className="text-xs sm:text-sm text-dark/70 leading-relaxed">Pantau status konfirmasi pesanan, invoice transaksi, dan detail jadwal seluruh acara Anda.</p>
                    </Link>

                    <Link to="/photobooth" className="bg-universal p-6 rounded-3xl border border-gray-100 shadow-sm hover:shadow-xl hover:shadow-emerald-500/10 hover:border-emerald-300 group transition-all duration-300">
                        <div className="w-14 h-14 bg-linear-to-br from-emerald-50 to-emerald-100 text-emerald-600 rounded-2xl flex items-center justify-center text-2xl mb-4 group-hover:scale-110 transition-transform duration-300 shadow-inner">
                            <FaCamera />
                        </div>
                        <h3 className="font-bold text-lg text-dark mb-1.5 group-hover:text-emerald-600 transition-colors">Photobooth Studio</h3>
                        <p className="text-xs sm:text-sm text-dark/70 leading-relaxed">Coba langsung pengalaman berfoto dengan strip template keren Memontra langsung dari browser.</p>
                    </Link>
                </div>

                {/* Recent Activity Section */}
                <div>
                    <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-6">
                        <div>
                            <div className="flex items-center gap-2">
                                <h2 className="text-2xl font-extrabold text-dark tracking-tight">Aktivitas Terakhir</h2>
                                <span className="bg-primary/10 text-primary text-xs font-bold px-2.5 py-1 rounded-full">
                                    {bookings.length} Pesanan
                                </span>
                            </div>
                            <p className="text-dark/60 mt-1 text-sm">Semua riwayat pemesanan dan kegiatan terbaru di akun Anda.</p>
                        </div>

                        {/* Filter Tabs */}
                        <div className="flex flex-wrap items-center gap-2">
                            <button
                                onClick={() => setFilter('all')}
                                className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${filter === 'all' ? 'bg-primary text-white shadow-sm' : 'bg-universal text-dark/70 hover:bg-gray-100 border border-gray-200'}`}
                            >
                                Semua
                            </button>
                            <button
                                onClick={() => setFilter('pending')}
                                className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer ${filter === 'pending' ? 'bg-amber-500 text-white shadow-sm' : 'bg-universal text-dark/70 hover:bg-gray-100 border border-gray-200'}`}
                            >
                                <span>Menunggu Bayar</span>
                                {pendingBookings.length > 0 && (
                                    <span className={`px-1.5 py-0.5 rounded-full text-[10px] ${filter === 'pending' ? 'bg-white text-amber-700' : 'bg-amber-100 text-amber-700'}`}>
                                        {pendingBookings.length}
                                    </span>
                                )}
                            </button>
                            <button
                                onClick={() => setFilter('paid')}
                                className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer ${filter === 'paid' ? 'bg-emerald-600 text-white shadow-sm' : 'bg-universal text-dark/70 hover:bg-gray-100 border border-gray-200'}`}
                            >
                                <span>Lunas</span>
                                {paidBookings.length > 0 && (
                                    <span className={`px-1.5 py-0.5 rounded-full text-[10px] ${filter === 'paid' ? 'bg-white text-emerald-800' : 'bg-emerald-100 text-emerald-800'}`}>
                                        {paidBookings.length}
                                    </span>
                                )}
                            </button>
                            <Link to="/riwayat-booking" className="text-primary font-bold hover:text-secondary text-xs sm:text-sm pl-2 transition-colors hidden md:inline-flex items-center gap-1">
                                Lihat Semua <FaArrowRight className="text-xs" />
                            </Link>
                        </div>
                    </div>

                    {/* Activity List Container */}
                    {loading ? (
                        <div className="bg-universal rounded-3xl p-12 text-center border border-gray-100 shadow-sm">
                            <div className="inline-block w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin"></div>
                            <p className="text-dark/50 text-sm mt-3 font-medium">Memuat aktivitas terbaru...</p>
                        </div>
                    ) : filteredBookings.length > 0 ? (
                        <div className="space-y-4">
                            {filteredBookings.slice(0, 5).map((item) => (
                                <div
                                    key={item.id}
                                    className="bg-universal rounded-3xl p-6 shadow-sm border border-gray-100 hover:shadow-md hover:border-primary/20 transition-all duration-300"
                                >
                                    {/* Top Bar Info */}
                                    <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 pb-4 mb-4 border-b border-gray-100">
                                        <div className="flex flex-wrap items-center gap-2.5">
                                            {/* Status Badge */}
                                            {item.payment_status === 'paid' ? (
                                                <span className="inline-flex items-center gap-1.5 bg-emerald-100 text-emerald-800 text-xs font-bold px-3 py-1 rounded-full">
                                                    <FaCheckCircle className="text-emerald-600" />
                                                    Lunas / Terkonfirmasi
                                                </span>
                                            ) : item.payment_status === 'pending' ? (
                                                <span className="inline-flex items-center gap-1.5 bg-amber-100 text-amber-800 text-xs font-bold px-3 py-1 rounded-full">
                                                    <FaClock className="text-amber-600" />
                                                    Menunggu Pembayaran
                                                </span>
                                            ) : (
                                                <span className="inline-flex items-center gap-1.5 bg-rose-100 text-rose-800 text-xs font-bold px-3 py-1 rounded-full">
                                                    <FaExclamationCircle className="text-rose-600" />
                                                    {item.payment_status || 'Dibatalkan'}
                                                </span>
                                            )}

                                            <span className="text-xs font-bold text-dark/40 uppercase tracking-wider">
                                                INV-MB-{item.id}
                                            </span>
                                        </div>

                                        <p className="text-xs text-dark/50 font-medium">
                                            Dipesan: {formatDateTime(item.created_at)}
                                        </p>
                                    </div>

                                    {/* Content Body */}
                                    <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
                                        <div className="space-y-2">
                                            <div className="flex items-center gap-3">
                                                <div className="w-11 h-11 rounded-2xl bg-primary/10 text-primary flex items-center justify-center text-lg shrink-0">
                                                    <FaCamera />
                                                </div>
                                                <div>
                                                    <h3 className="text-xl font-bold text-dark tracking-tight">
                                                        Paket {item.package}
                                                    </h3>
                                                    <p className="text-sm text-dark/60 font-medium">
                                                        Acara {item.event_type}
                                                    </p>
                                                </div>
                                            </div>

                                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                                                <div className="flex items-center gap-2 text-xs sm:text-sm text-dark/70">
                                                    <FaCalendarAlt className="text-orange-500 shrink-0" />
                                                    <span>{item.date} • {item.time}</span>
                                                </div>
                                                <div className="flex items-center gap-2 text-xs sm:text-sm text-dark/70">
                                                    <FaMapMarkerAlt className="text-blue-500 shrink-0" />
                                                    <span className="truncate">{item.address}, {item.city}</span>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Price and Actions */}
                                        <div className="flex flex-col sm:flex-row lg:flex-col items-start lg:items-end justify-between gap-3 shrink-0 pt-4 lg:pt-0 border-t lg:border-t-0 border-gray-100">
                                            <div>
                                                <p className="text-xs text-dark/50 font-medium lg:text-right">Total Tagihan</p>
                                                <p className="text-xl sm:text-2xl font-black text-dark lg:text-right">
                                                    {formatCurrency(item.total_price)}
                                                </p>
                                            </div>

                                            <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
                                                {item.payment_status === 'pending' && (
                                                    <>
                                                        {item.snap_token ? (
                                                            <button
                                                                onClick={() => navigate('/payment', { state: { booking: item, snapToken: item.snap_token } })}
                                                                className="bg-primary hover:bg-primary-dark text-white font-bold text-xs sm:text-sm px-5 py-2.5 rounded-xl shadow-sm hover:shadow transition-all flex items-center gap-2 cursor-pointer"
                                                            >
                                                                <FaCreditCard /> Bayar Sekarang
                                                            </button>
                                                        ) : (
                                                            <Link
                                                                to="/riwayat-booking"
                                                                className="bg-primary hover:bg-primary-dark text-white font-bold text-xs sm:text-sm px-5 py-2.5 rounded-xl shadow-sm hover:shadow transition-all"
                                                            >
                                                                Lanjutkan
                                                            </Link>
                                                        )}

                                                        {isLocalhost && (
                                                            <button
                                                                onClick={() => handleSimulatePayment(item.id)}
                                                                disabled={simulatingId === item.id}
                                                                className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs px-3.5 py-2.5 rounded-xl transition-all disabled:opacity-50 cursor-pointer"
                                                                title="Simulasi pelunasan pembayaran via localhost"
                                                            >
                                                                {simulatingId === item.id ? 'Memproses...' : '✅ Simulasi Lunas'}
                                                            </button>
                                                        )}
                                                    </>
                                                )}

                                                <Link
                                                    to="/riwayat-booking"
                                                    className="bg-gray-100 hover:bg-gray-200 text-dark/80 font-bold text-xs sm:text-sm px-4 py-2.5 rounded-xl transition-all"
                                                >
                                                    Detail Pesanan
                                                </Link>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}

                            {/* Additional Activity: Registration Milestone */}
                            {filter === 'all' && (
                                <div className="bg-universal/80 rounded-3xl p-6 border border-gray-100 flex items-start gap-4 shadow-xs">
                                    <div className="w-11 h-11 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center text-lg shrink-0">
                                        <FaUserCheck />
                                    </div>
                                    <div className="grow">
                                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 mb-1">
                                            <h4 className="font-bold text-dark text-base">Pendaftaran Akun Memontra</h4>
                                            <span className="text-xs text-dark/40 font-medium">
                                                {formatDateTime(user?.created_at)}
                                            </span>
                                        </div>
                                        <p className="text-xs sm:text-sm text-dark/60 leading-relaxed">
                                            Selamat datang! Akun Anda atas nama <span className="font-semibold text-dark">{user?.name}</span> ({user?.email}) telah aktif dan siap digunakan untuk memesan photobooth kapan saja.
                                        </p>
                                    </div>
                                </div>
                            )}

                            {filteredBookings.length > 5 && (
                                <div className="text-center pt-2">
                                    <Link
                                        to="/riwayat-booking"
                                        className="inline-flex items-center gap-2 text-sm font-bold text-primary hover:text-secondary transition-colors"
                                    >
                                        Lihat {filteredBookings.length - 5} pesanan lainnya di halaman Riwayat Pesanan <FaArrowRight className="text-xs" />
                                    </Link>
                                </div>
                            )}
                        </div>
                    ) : (
                        /* Empty State if filter yields no items */
                        <div className="bg-universal rounded-3xl border border-dashed border-gray-200 p-10 sm:p-14 text-center">
                            <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center text-4xl mb-4 mx-auto text-primary">
                                {filter === 'pending' ? <FaClock className="text-amber-500" /> : filter === 'paid' ? <FaCheckCircle className="text-emerald-500" /> : <FaRegSmileBeam />}
                            </div>
                            <h3 className="font-bold text-dark text-xl mb-2">
                                {filter === 'pending'
                                    ? 'Tidak Ada Tagihan Menunggu'
                                    : filter === 'paid'
                                        ? 'Belum Ada Pesanan Lunas'
                                        : 'Belum Ada Aktivitas Pesanan'}
                            </h3>
                            <p className="text-dark/60 text-sm max-w-md mx-auto mb-6">
                                {filter === 'pending'
                                    ? 'Semua pesanan Anda sudah dibayar atau belum ada tagihan aktif. Anda dapat memesan photobooth baru sekarang.'
                                    : filter === 'paid'
                                        ? 'Anda belum memiliki pesanan yang berstatus lunas. Selesaikan pembayaran pesanan Anda untuk mulai memproses jadwal.'
                                        : 'Anda belum memiliki riwayat pemesanan. Yuk buat momen tak terlupakan bersama Memontra Booth!'}
                            </p>

                            <div className="flex flex-wrap justify-center gap-3">
                                {filter !== 'all' ? (
                                    <button
                                        onClick={() => setFilter('all')}
                                        className="bg-gray-100 hover:bg-gray-200 text-dark font-bold px-6 py-3 rounded-xl text-sm transition-all cursor-pointer"
                                    >
                                        Tampilkan Semua Aktivitas
                                    </button>
                                ) : (
                                    <Link
                                        to="/booking"
                                        className="bg-primary text-universal font-extrabold px-8 py-3.5 rounded-xl hover:bg-primary/90 transition-all shadow-md shadow-primary/20"
                                    >
                                        Mulai Booking Sekarang
                                    </Link>
                                )}
                            </div>

                            {/* Show registration milestone even if 0 bookings */}
                            {filter === 'all' && (
                                <div className="mt-10 pt-8 border-t border-gray-100 max-w-md mx-auto text-left flex items-center gap-3 bg-gray-50/70 p-4 rounded-2xl">
                                    <div className="w-9 h-9 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center shrink-0">
                                        <FaUserCheck className="text-sm" />
                                    </div>
                                    <div className="text-xs">
                                        <p className="font-bold text-dark">Akun Anda Terdaftar</p>
                                        <p className="text-dark/50">Bergabung pada: {formatDateTime(user?.created_at)}</p>
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </div>

            </main>

            <Footer />
        </div>
    );
};

export default UserDashboard;

