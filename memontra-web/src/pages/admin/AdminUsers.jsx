import React, { useEffect, useState } from 'react';
import axios from '../../lib/axios';
import AdminLayout from '../../components/layouts/AdminLayout';

const AdminUsers = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Fetch users if endpoint exists, otherwise fallback to mock
        const fetchUsers = async () => {
            try {
                const response = await axios.get('/api/users');
                setUsers(response.data);
            } catch (error) {
                console.error("Error fetching users", error);
                // Mock data fallback
                setUsers([
                    { id: 1, name: 'Admin Memontra', email: 'admin@memontra.com', is_admin: 1, created_at: '2023-10-01' },
                    { id: 2, name: 'Test User', email: 'test@example.com', is_admin: 0, created_at: '2023-10-05' },
                ]);
            } finally {
                setLoading(false);
            }
        };
        fetchUsers();
    }, []);

    return (
        <AdminLayout>
            <div className="max-w-7xl mx-auto w-full pb-10">
                <div className="mb-8 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-3xl sm:text-4xl font-extrabold text-gray-900 tracking-tight">Data Pengguna</h1>
                        <p className="text-gray-500 mt-2">Kelola daftar pelanggan dan hak akses admin.</p>
                    </div>
                </div>

                <div className="bg-white rounded-[32px] shadow-sm border border-gray-100 overflow-hidden">
                    <div className="p-6 sm:p-8 border-b border-gray-100 bg-white/50 backdrop-blur-xl">
                        <h2 className="text-xl font-bold text-gray-800">Daftar Akun Terdaftar</h2>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-gray-50/50">
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">ID</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Nama & Email</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Peran (Role)</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Tanggal Bergabung</th>
                                    <th className="px-6 py-5 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Aksi</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-50">
                                {loading ? (
                                    <tr>
                                        <td colSpan="5" className="text-center py-16">
                                            <div className="inline-block w-10 h-10 border-4 border-primary/30 border-t-primary rounded-full animate-spin"></div>
                                        </td>
                                    </tr>
                                ) : (Array.isArray(users) ? users : []).map((user) => (
                                    <tr key={user.id} className="hover:bg-gray-50/50 transition-colors">
                                        <td className="px-6 py-5">
                                            <span className="text-gray-500 font-medium">#{user.id}</span>
                                        </td>
                                        <td className="px-6 py-5">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold">
                                                    {user.name.charAt(0).toUpperCase()}
                                                </div>
                                                <div>
                                                    <p className="font-bold text-gray-900">{user.name}</p>
                                                    <p className="text-sm text-gray-500">{user.email}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-5">
                                            {user.is_admin ? (
                                                <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-purple-50 text-purple-600 border border-purple-100">
                                                    Administrator
                                                </span>
                                            ) : (
                                                <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-gray-100 text-gray-600 border border-gray-200">
                                                    Pelanggan
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-6 py-5 text-sm text-gray-600">
                                            {new Date(user.created_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}
                                        </td>
                                        <td className="px-6 py-5 text-right">
                                            <button className="text-gray-400 hover:text-primary transition-colors p-2">
                                                ⚙️
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminUsers;
