import React, { useEffect, useState, useCallback } from 'react';
import axios from '../../lib/axios';
import AdminLayout from '../../components/layouts/AdminLayout';
import { useNavigate } from 'react-router-dom';
import { FaRecycle } from 'react-icons/fa';

const AdminDashboard = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [stats, setStats] = useState({ totalRevenue: 0, totalBookings: 0, pendingBookings: 0 });
    const navigate = useNavigate();



    const fetchBookings = useCallback(async () => {
        setLoading(true);
        try {
            const response = await axios.get('/api/bookings');
            const data = response.data || [];

            let revenue = 0;
            let pending = 0;
            data.forEach(b => {
                if (b.payment_status === 'paid') revenue += Number(b.total_price || 0);
                if (b.payment_status === 'pending') pending++;
            });

            setStats({
                totalRevenue: revenue,
                totalBookings: data.length,
                pendingBookings: pending
            });

            setBookings(data.slice(0, 5));
        } catch (error) {
            console.error("Error fetching bookings", error);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        let isMounted = true;
        const load = async () => {
            try {
                const response = await axios.get('/api/bookings');
                const data = response.data || [];

                let revenue = 0;
                let pending = 0;
                data.forEach(b => {
                    if (b.payment_status === 'paid') revenue += Number(b.total_price || 0);
                    if (b.payment_status === 'pending') pending++;
                });

                if (isMounted) {
                    setStats({
                        totalRevenue: revenue,
                        totalBookings: data.length,
                        pendingBookings: pending
                    });
                    setBookings(data.slice(0, 5));
                }
            } catch (error) {
                console.error("Error fetching bookings", error);
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

    const getStatusColor = (status) => {
        switch (status) {
            case 'paid': return 'bg-green-100 text-green-700';
            case 'pending': return 'bg-orange-100 text-orange-700';
            case 'failed': return 'bg-red-100 text-red-700';
            default: return 'bg-gray-100 text-gray-700';
        }
    };

    return (
        <AdminLayout>
            <div className="max-w-7xl mx-auto w-full pb-10">
                <div className="mb-10 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
                    <div>
                        <h1 className="text-3xl sm:text-4xl font-extrabold text-gray-900 tracking-tight">Ringkasan Dashboard</h1>
                        <p className="text-gray-500 mt-2">Selamat datang kembali! Berikut adalah statistik hari ini.</p>
                    </div>
                    <div className="flex gap-3">
                        <button onClick={fetchBookings} className="bg-white text-gray-600 hover:text-primary font-bold px-5 py-2.5 rounded-2xl shadow-sm border border-gray-100 transition-all flex items-center gap-2">
                            <span><FaRecycle /></span> Refresh
                        </button>
                    </div>
                </div>

                {/* Stats Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
                    <div className="bg-white rounded-[28px] p-6 sm:p-8 shadow-sm border border-gray-100 relative overflow-hidden">
                        <div className="absolute -right-6 -top-6 w-32 h-32 bg-primary/5 rounded-full blur-2xl"></div>
                        <div className="relative z-10">
                            <p className="text-gray-500 font-medium mb-1">Total Pendapatan</p>
                            <h3 className="text-3xl font-extrabold text-gray-900">Rp {new Intl.NumberFormat('id-ID').format(stats.totalRevenue)}</h3>
                            <div className="mt-4 flex items-center text-sm font-semibold text-green-500 bg-green-50 w-max px-3 py-1 rounded-lg">
                                + Pembayaran Sukses
                            </div>
                        </div>
                    </div>
                    <div className="bg-white rounded-[28px] p-6 sm:p-8 shadow-sm border border-gray-100 relative overflow-hidden">
                        <div className="absolute -right-6 -top-6 w-32 h-32 bg-orange-500/5 rounded-full blur-2xl"></div>
                        <div className="relative z-10">
                            <p className="text-gray-500 font-medium mb-1">Total Pesanan</p>
                            <h3 className="text-3xl font-extrabold text-gray-900">{stats.totalBookings}</h3>
                            <div className="mt-4 flex items-center text-sm font-semibold text-primary bg-primary/10 w-max px-3 py-1 rounded-lg">
                                Sepanjang Waktu
                            </div>
                        </div>
                    </div>
                    <div className="bg-white rounded-[28px] p-6 sm:p-8 shadow-sm border border-gray-100 relative overflow-hidden">
                        <div className="absolute -right-6 -top-6 w-32 h-32 bg-red-500/5 rounded-full blur-2xl"></div>
                        <div className="relative z-10">
                            <p className="text-gray-500 font-medium mb-1">Menunggu Pembayaran</p>
                            <h3 className="text-3xl font-extrabold text-gray-900">{stats.pendingBookings}</h3>
                            <div className="mt-4 flex items-center text-sm font-semibold text-orange-500 bg-orange-50 w-max px-3 py-1 rounded-lg">
                                Butuh Tindakan
                            </div>
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-[32px] shadow-sm border border-gray-100 overflow-hidden">
                    <div className="p-6 sm:p-8 border-b border-gray-100 flex justify-between items-center bg-white/50 backdrop-blur-xl">
                        <h2 className="text-xl font-bold text-gray-800">Pemesanan Terbaru</h2>
                        <button onClick={() => navigate('/admin/bookings')} className="text-sm font-bold text-primary hover:text-primary-dark transition-colors bg-primary/10 hover:bg-primary/20 px-5 py-2.5 rounded-xl">
                            Lihat Semua
                        </button>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/50">
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Pelanggan</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Paket</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Waktu</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Total</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {loading ? (
                                    <tr>
                                        <td colSpan="5" className="text-center py-12">
                                            <div className="inline-block w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin"></div>
                                        </td>
                                    </tr>
                                ) : bookings.length === 0 ? (
                                    <tr>
                                        <td colSpan="5" className="text-center py-16">
                                            <p className="text-gray-500">Belum ada pemesanan.</p>
                                        </td>
                                    </tr>
                                ) : (
                                    bookings.map((booking) => (
                                        <tr key={booking.id} className="hover:bg-gray-50/50 transition-colors">
                                            <td className="px-6 py-4 align-middle">
                                                <p className="font-bold text-gray-900">{booking.user?.name || 'Guest'}</p>
                                                <p className="text-xs text-gray-400">INV-MB-{booking.id}</p>
                                            </td>
                                            <td className="px-6 py-4 align-middle">
                                                <span className="font-medium text-gray-800">{booking.package}</span>
                                            </td>
                                            <td className="px-6 py-4 align-middle">
                                                <p className="text-sm font-semibold text-gray-800">{booking.date}</p>
                                            </td>
                                            <td className="px-6 py-4 align-middle">
                                                <p className="font-bold text-gray-900">Rp {new Intl.NumberFormat('id-ID').format(booking.total_price)}</p>
                                            </td>
                                            <td className="px-6 py-4 align-middle">
                                                <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${getStatusColor(booking.payment_status)}`}>
                                                    {booking.payment_status}
                                                </span>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminDashboard;
