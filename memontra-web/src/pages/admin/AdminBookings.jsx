import React, { useEffect, useState, useCallback } from 'react';
import axios from '../../lib/axios';
import AdminLayout from '../../components/layouts/AdminLayout';
import { FaRecycle, FaLocationDot } from 'react-icons/fa6';
import { FaMap } from 'react-icons/fa';

const AdminBookings = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    const fetchBookings = useCallback(async () => {
        setLoading(true);
        try {
            const response = await axios.get('/api/bookings');
            setBookings(response.data || []);
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
                if (isMounted) {
                    setBookings(response.data || []);
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

    const filteredBookings = Array.isArray(bookings) ? bookings.filter(b =>
        b?.id?.toString().includes(searchTerm) ||
        (b?.user?.name || '').toLowerCase().includes(searchTerm.toLowerCase())
    ) : [];

    return (
        <AdminLayout>
            <div className="max-w-7xl mx-auto w-full pb-10">
                <div className="mb-8 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-3xl sm:text-4xl font-extrabold text-gray-900 tracking-tight">Manajemen Pesanan</h1>
                        <p className="text-gray-500 mt-2">Daftar seluruh transaksi dan penyewaan photobooth.</p>
                    </div>
                </div>

                <div className="bg-white rounded-[32px] shadow-sm border border-gray-100 overflow-hidden">
                    <div className="p-6 sm:p-8 border-b border-gray-100 flex flex-col sm:flex-row justify-between items-center gap-4 bg-white/50 backdrop-blur-xl">
                        <div className="relative w-full sm:w-96">
                            <input
                                type="text"
                                placeholder="Cari ID Pesanan atau Nama..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                className="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-2xl outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                            />
                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
                        </div>
                        <button onClick={fetchBookings} className="text-sm font-bold text-primary hover:text-primary-dark transition-colors bg-primary/10 hover:bg-primary/20 px-5 py-3 rounded-2xl flex items-center gap-2 w-full sm:w-auto justify-center">
                            <span><FaRecycle /></span> Segarkan
                        </button>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/50">
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">ID / Pelanggan</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Detail Paket</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Pelaksanaan</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Harga</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status Pembayaran</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {loading ? (
                                    <tr>
                                        <td colSpan="5" className="text-center py-16">
                                            <div className="inline-block w-10 h-10 border-4 border-primary/30 border-t-primary rounded-full animate-spin"></div>
                                        </td>
                                    </tr>
                                ) : filteredBookings.length === 0 ? (
                                    <tr>
                                        <td colSpan="5" className="text-center py-20">
                                            <div className="text-6xl mb-4 grayscale opacity-40">📭</div>
                                            <p className="text-gray-500 font-medium">Tidak ada data pesanan ditemukan.</p>
                                        </td>
                                    </tr>
                                ) : (
                                    filteredBookings.map((booking) => (
                                        <tr key={booking.id} className="hover:bg-gray-50/50 transition-colors group">
                                            <td className="px-6 py-5 align-top">
                                                <p className="font-bold text-gray-900">INV-MB-{booking.id}</p>
                                                <p className="text-sm text-gray-500 mt-1 font-medium">{booking.user?.name || 'Guest'}</p>
                                                <p className="text-xs text-gray-400">{booking.user?.email}</p>
                                            </td>
                                            <td className="px-6 py-5 align-top">
                                                <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-600 border border-blue-100 mb-2">
                                                    {booking.package}
                                                </span>
                                                <p className="text-sm font-medium text-gray-700 capitalize">{booking.event_type}</p>
                                            </td>
                                            <td className="px-6 py-5 align-top">
                                                <p className="text-sm font-bold text-gray-800">{booking.date} <span className="text-gray-400 font-normal">| {booking.time}</span></p>
                                                <p className="text-xs text-gray-500 mt-1 max-w-[200px] truncate" title={`${booking.address}, ${booking.city}`}>
                                                    <FaLocationDot /> {booking.address}, {booking.city}
                                                </p>
                                                {booking.latitude && booking.longitude && (
                                                    <a
                                                        href={`https://www.google.com/maps/search/?api=1&query=${booking.latitude},${booking.longitude}`}
                                                        target="_blank"
                                                        rel="noreferrer"
                                                        className="text-[10px] inline-flex items-center gap-1 font-bold text-blue-500 hover:text-blue-700 mt-1 bg-blue-50 px-2 py-0.5 rounded-full"
                                                    >
                                                        <FaMap /> Lihat di Maps
                                                    </a>
                                                )}
                                            </td>
                                            <td className="px-6 py-5 align-top">
                                                <p className="font-bold text-primary text-lg">Rp {new Intl.NumberFormat('id-ID').format(booking.total_price)}</p>
                                            </td>
                                            <td className="px-6 py-5 align-top">
                                                <span className={`inline-flex items-center px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider shadow-sm ${getStatusColor(booking.payment_status)}`}>
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

export default AdminBookings;
