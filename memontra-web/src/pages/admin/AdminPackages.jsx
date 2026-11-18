import React from 'react';
import AdminLayout from '../../components/layouts/AdminLayout';
import { FaPlus, FaPencil } from 'react-icons/fa6';

const AdminPackages = () => {
    // Mock data untuk saat ini
    const packages = [
        { id: 1, name: 'Silver', price: 600000, duration: '2 Jam', status: 'Aktif' },
        { id: 2, name: 'Gold', price: 1000000, duration: '4 Jam', status: 'Aktif' },
        { id: 3, name: 'Platinum', price: 1500000, duration: '6 Jam', status: 'Aktif' },
    ];

    return (
        <AdminLayout>
            <div className="max-w-7xl mx-auto w-full pb-10">
                <div className="mb-8 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-3xl sm:text-4xl font-extrabold text-gray-900 tracking-tight">Manajemen Paket</h1>
                        <p className="text-gray-500 mt-2">Atur harga dan fitur paket layanan photobooth Anda.</p>
                    </div>
                    <button className="bg-primary text-white font-bold px-6 py-3 rounded-2xl shadow-md hover:bg-primary-dark hover:-translate-y-0.5 transition-all flex items-center gap-2">
                        <span><FaPlus /></span> Tambah Paket Baru
                    </button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {packages.map(pkg => (
                        <div key={pkg.id} className="bg-white rounded-[32px] p-8 shadow-sm border border-gray-100 hover:shadow-xl hover:border-primary/20 transition-all duration-300 relative overflow-hidden group">
                            <div className="absolute -right-10 -top-10 w-32 h-32 bg-primary/5 rounded-full blur-2xl group-hover:bg-primary/10 transition-colors"></div>

                            <div className="flex justify-between items-start mb-6 relative z-10">
                                <div>
                                    <h3 className="text-2xl font-extrabold text-gray-900">{pkg.name}</h3>
                                    <span className="inline-block mt-2 px-3 py-1 bg-green-50 text-green-600 text-xs font-bold rounded-full">{pkg.status}</span>
                                </div>
                                <button className="w-10 h-10 rounded-xl bg-gray-50 text-gray-500 hover:bg-primary/10 hover:text-primary flex items-center justify-center transition-colors">
                                    <FaPencil />
                                </button>
                            </div>

                            <div className="space-y-4 mb-8 relative z-10">
                                <div>
                                    <p className="text-sm text-gray-500 font-medium">Harga Dasar</p>
                                    <p className="text-xl font-bold text-primary">Rp {new Intl.NumberFormat('id-ID').format(pkg.price)}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-gray-500 font-medium">Durasi Standar</p>
                                    <p className="font-semibold text-gray-800">{pkg.duration}</p>
                                </div>
                            </div>

                            <button className="w-full py-3 rounded-xl border-2 border-gray-100 text-gray-600 font-bold hover:border-primary hover:text-primary transition-colors relative z-10">
                                Lihat Detail Fitur
                            </button>
                        </div>
                    ))}
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminPackages;
